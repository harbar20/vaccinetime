require 'rest-client'
require 'nokogiri'

require_relative '../sentry_helper'
require_relative './base_clinic'

module Acuity
  SITES = {
    'Southbridge Community Center (non-local residents) in Southbridge, MA' => {
      sign_up_url: 'https://www.harringtonhospital.org/coronavirus/covid-19-vaccination/',
      api_url: 'https://app.acuityscheduling.com/schedule.php?action=showCalendar&fulldate=1&owner=22192301&template=weekly',
      api_params: {
        type: 20819310,
        calendar: 5202038,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: 5202038,
      },
    },

    'Southbridge Community Center (local residents only) in Southbridge, MA' => {
      sign_up_url: 'https://www.harringtonhospital.org/coronavirus/covid-19-vaccination/',
      api_url: 'https://app.acuityscheduling.com/schedule.php?action=showCalendar&fulldate=1&owner=22192301&template=weekly',
      api_params: {
        type: 20926295,
        calendar: 5202050,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: 5202050,
      },
    },

    '700 Essex St. (GLFHC patients only) in Lawrence, MA' => {
      sign_up_url: 'https://glfhc.org/covid-19-vaccine-signup-form/',
      api_url: 'https://glfhccovid19iz.as.me/schedule.php?action=showCalendar&fulldate=1&owner=21956779&template=weekly&location=700+Essex+Street%2C+Lawrence+MA',
      api_params: {
        type: 20223228,
        calendar: 5075244,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: '',
      },
    },

    '147 Pelham St. in Methuen, MA' => {
      sign_up_url: 'https://glfhc.org/covid-19-vaccine-signup-form/',
      api_url: 'https://glfhccovid19iz.as.me/schedule.php?action=showCalendar&fulldate=1&owner=21956779&template=weekly',
      api_params: {
        type: 20223228,
        calendar: 5114836,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: 5114836,
      },
    },

    'Central Plaza - 2 Water St. in Haverhill, MA' => {
      sign_up_url: 'https://glfhc.org/covid-19-vaccine-signup-form/',
      api_url: 'https://glfhccovid19iz.as.me/schedule.php?action=showCalendar&fulldate=1&owner=21956779&template=weekly&location=Central+Plaza%2C+2+Water+Street%2C+Haverhill+MA',
      api_params: {
        type: 20223228,
        calendar: 5236989,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: '',
      },
    },

    'Northern Essex Community College 45 Franklin St. (Lawrence residents only) in Lawrence, MA' => {
      sign_up_url: 'https://glfhc.org/covid-19-vaccine-signup-form/',
      api_url: 'https://glfhccovid19iz.as.me/schedule.php?action=showCalendar&fulldate=1&owner=21956779&template=weekly&location=45+Franklin+Street%2C+Lawrence+MA',
      api_params: {
        type: 20223228,
        calendar: 5341082,
        skip: true,
        'options[qty]' => 1,
        'options[numDays]' => 27,
        ignoreAppointment: '',
        appointmentType: '',
        calendarID: '',
      },
    },

    # NOTE: Trinity is showing a message that all appointment types are private
    #'Trinity EMS in Haverhill, MA' => {
      #sign_up_url: 'https://trinityems.com/what-we-do/covid-19-vaccine-clinics/',
      #api_url: 'https://app.acuityscheduling.com/schedule.php?action=showCalendar&fulldate=1&owner=21713854&template=weekly',
      #api_params: {
        #type: 19620839,
        #calendar: 5109380,
        #skip: true,
        #'options[qty]' => 1,
        #'options[numDays]' => 5,
        #ignoreAppointment: '',
        #appointmentType: '',
        #calendarID: 5109380,
      #},
    #}
  }.freeze

  def self.all_clinics(storage, logger)
    SITES.flat_map do |site_name, config|
      sleep(1)
      SentryHelper.catch_errors(logger, 'Acuity') do
        logger.info "[Acuity] Checking site #{site_name}"
        fetch_appointments(config).map do |date, appointments|
          logger.info "[Acuity] Site #{site_name} found #{appointments} appointments on #{date}"
          Clinic.new(storage, site_name, date, appointments, config[:sign_up_url])
        end
      end
    end
  end

  def self.fetch_appointments(config)
    res = RestClient.post(config[:api_url], config[:api_params])
    html = Nokogiri::HTML(res.body)
    html.search('input.time-selection').each_with_object(Hash.new(0)) do |appt, h|
      h[appt['data-readable-date']] += 1
    end
  end

  class Clinic < BaseClinic
    attr_reader :name, :date, :appointments, :link

    def initialize(storage, name, date, appointments, link)
      super(storage)
      @name = name
      @date = date
      @appointments = appointments
      @link = link
    end

    def title
      "#{name} on #{date}"
    end
  end
end
