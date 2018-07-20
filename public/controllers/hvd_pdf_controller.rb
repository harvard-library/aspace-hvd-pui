require 'java'
require 'pp'
require 'open-uri'

class HvdPdfController <  ApplicationController

  PDF_MUTEX = java.util.concurrent.Semaphore.new(AppConfig[:pui_max_concurrent_pdfs])

  def fetch
    repo_id = params.fetch(:rid, nil)
    resource_id = params.fetch(:id, nil)
    token = params.fetch(:token, nil)

    uri = "/repositories/#{params[:rid]}/resources/#{params[:id]}"
    begin
      result = archivesspace.get_record(uri, {'resolve[]' => ['resource:id@compact_resource']})
      ead_id = result.ead_id || nil
      pdf_name = ''
      if ead_id.nil?
        pdf_name = "_repositories_#{params[:rid]}_resources_#{params[:id]}.pdf"
      else
        pdf_name = "#{ead_id}.pdf"
      end
      pdf_url = "#{AppConfig[:pui_stored_pdfs_url]}/#{pdf_name}"
#    Rails.logger.debug("PDF url: #{pdf_url}")
       if token
        token.gsub!(/[^a-f0-9]/, '')
        cookies["pdf_generated_#{token}"] = { value: token, expires: 5.minutes.from_now }
      end
    # h/t https://stackoverflow.com/questions/12279056/rails-allow-download-of-files-stored-on-s3-without-showing-the-actual-s3-url-to#answer-12281634
      data = open(pdf_url)
      send_data data.read.force_encoding('BINARY'), :filename => pdf_name, :type => "application/pdf", :disposition => "attachment", :stream => 'true'
    rescue RecordNotFound
      render  'shared/not_found', :status => 404
    rescue OpenURI::HTTPError => ouerr
      redirect_to("#{uri}/hvd_pdf") and return
    rescue Exception => bang
      flash[:error] = I18n.t('errors.unexpected_error')
      Rails.logger.debug("ERROR RETRIEVING PDF: " + bang.pretty_inspect)
      redirect_back(fallback_location: uri) and return
    end
  end

  def resource
    PDF_MUTEX.acquire
    begin
      repo_id = params.fetch(:rid, nil)
      resource_id = params.fetch(:id, nil)
      token = params.fetch(:token, nil)

      pdf = HvdPDF.new(repo_id, resource_id, archivesspace, "#{request.protocol}#{request.host_with_port}")
      pdf_file = pdf.generate

      if token
        token.gsub!(/[^a-f0-9]/, '')
        cookies["pdf_generated_#{token}"] = { value: token, expires: 5.minutes.from_now }
      end

      respond_to do |format|
        filename = pdf.suggested_filename

        format.all do
          fh = File.open(pdf_file.path, "r")
          self.headers["Content-type"] = "application/pdf"
          self.headers["Content-disposition"] = "attachment; filename=\"#{filename}\""
          self.response_body = Enumerator.new do |y|
            begin
              while chunk = fh.read(4096)
                y << chunk
              end
            ensure
              fh.close
              pdf_file.unlink
            end
          end
        end
      end
    ensure
      PDF_MUTEX.release
    end
  end

end
