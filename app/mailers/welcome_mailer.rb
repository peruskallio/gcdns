class WelcomeMailer < ActionMailer::Base
  def added(adder, added, token)
    @added = added
    @adder = adder
    @token = token
    mail(to: added.email, from: adder.email, subject: "You were added to GCDNS by #{adder.email}")
  end
end