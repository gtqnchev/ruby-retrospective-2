class PrivacyFilter
  attr_accessor :preserve_phone_country_code, :preserve_email_hostname, :partially_preserve_email_username

  def initialize(text)
    @text = text
    @preserve_phone_country_code = false
    @preserve_email_hostname = false
    @partially_preserve_email_username = false
  end

  def filtered
    filter_emails(filter_phones(@text))
  end

  def filter_phones(text)
    if preserve_phone_country_code
      filtered = text.gsub(/(?<code>(00|\+)[1-9]\d{,2})([- ()]{,2}\d){6,11}/, '\k<code> [FILTERED]')
      filtered.gsub(/(0[- ()]{,2}[1-9]([- ()]{,2}\d){5,10})/, '[PHONE]')
    else
      text.gsub(/((00|\+)[1-9]\d{,2}([- ()]{,2}\d){6,11})|(0[- ()]{,2}[1-9]([- ()]{,2}\d){5,10})/, '[PHONE]')
    end
  end

  def filter_emails(text)
    text.gsub(/([0-9a-zA-Z])[-\+\.\w]{,200}@(\g<1>([-0-9a-zA-Z]{,61}\g<1>)?\.)+[a-zA-Z]{2,3}(\.[a-zA-Z]{2})?/) do |mail|
      if !preserve_email_hostname and !partially_preserve_email_username
        "[EMAIL]"
      else
        filter_email(mail)
      end
    end
  end

  private

  def filter_email(email)
    name, host = email.split(/@/)
    filter_name(name) + "@" + host
  end

  def filter_name(name)
    if partially_preserve_email_username and name.size >= 6
      name.gsub(/(?<=[-\+\.\w]{3})[-\+\.\w]+/, "[FILTERED]")
    elsif preserve_email_hostname
      "[FILTERED]"
    end
  end
end

module Validations
  def self.date?(value)
    !!(/\A\d{4}-(0[1-9]|1[012])-(0[1-9]|[12]\d|3[01])\z/ =~ value)
  end

  def self.time?(value)
    !!(/\A([01]\d|2[0-3]):[0-5]\d:[0-5]\d\z/ =~ value)
  end

  def self.date_time?(value)
    date, time = value.split(/[ T]/, 2)
    !!date?(date) and !!time?(time)
  end

  def self.integer?(value)
    !!(/\A-?(0|[1-9]\d*)\z/ =~ value)
  end

  def self.number?(value)
    !!(/\A-?(0|[1-9]\d*)(\.\d+)?\z/ =~ value)
  end

  def self.ip_address?(value)
    !!(/\A(0|[1-9]\d?|2[0-5]{2}).\g<1>.\g<1>.\g<1>/ =~ value)
  end

  def self.hostname?(value)
    !!(/\A([0-9a-zA-Z]([-0-9a-zA-Z]{,61}[0-9a-zA-Z])?\.)+[a-zA-Z]{2,3}(\.[a-zA-Z]{2})?\z/ =~ value)
  end

  def self.phone?(value)
    !!(/\A0[- ()]{,2}[1-9]([- ()]{,2}\d){5,10}\z/   =~ value) or
    !!(/\A(00|\+)[1-9]\d{,2}([- ()]{,2}\d){6,11}\z/ =~ value)
  end

  def self.email?(value)
    name, host = value.split(/@/, 2)
    !!(/\A[0-9a-zA-Z][-\+\.\w]{,200}/ =~ name and hostname?(host))
  end
end