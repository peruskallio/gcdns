# Avoid certificate verification errors
ENV["SSL_CERT_FILE"] = File.join(Rails.root, 'config', 'ssl', 'cacert.pem')