class Views::Devise::Mailer::ResetPasswordInstructions < Views::Mailer::Base

  def main
    p {
      text "Hello "
      text(resource.email)
      text "!"
    }


    p("Someone has requested a link to change your password. You can do this through the link below.")

    p {
      link_to 'Change my password', edit_password_url(resource, reset_password_token: token)
    }


    p("If you didn't request this, please ignore this email.")
    p("Your password won't change until you access the link above and create a new one.")
  end
end
