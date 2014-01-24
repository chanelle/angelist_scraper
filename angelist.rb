require 'rest-client'
require 'pry'
require 'pry-debugger'
require 'json'
require 'google_drive'

class JobScraper
  attr_accessor :all_worksheets, :companies, :company_names, :sheet_name, :working_sheet, :new_companies
  
  def initialize sheet_name
    @sheet_name = sheet_name
    @session = GoogleDrive.login(ENV["GMAIL_EMAIL"], ENV["GMAIL_PWD"])
    @location_code = 1692
    @all_worksheets = @session.spreadsheet_by_key(ENV["JOBS_SPREADSHEET"]).worksheets
    @working_sheet = nil
    @company_names = []
    @new_companies = {}
    self.get_companies
    self.aggregate_listed_company_names
    self.fetch_all_jobs
    self.save_new_companies
  end

  def get_companies
    @all_worksheets.each do |sheet|
      if sheet.title == @sheet_name
        @working_sheet = sheet
        @companies = @working_sheet.rows
      end
    end
  end

  def aggregate_listed_company_names
    @companies.each_with_index do |row, index|
      next if index == 0
      @company_names.push row[0]
    end
  end

  def company_present? company_name
    return true if self.company_names.include? company_name
  end

  def fetch_all_jobs
    jobs = JSON.parse RestClient.get "https://api.angel.co/1/tags/#{@location_code}/jobs"
    total_listings = jobs["total"].to_i
    server_calls = total_listings / 50
    final_server_call = total_listings % 50

    server_calls.times do |n|
      next if n == 0
      fetch_page_of_jobs n
    end

    if final_server_call > 0
      fetch_page_of_jobs server_calls + 1
    end

  end

  def fetch_page_of_jobs page
    jobs = JSON.parse RestClient.get "https://api.angel.co/1/tags/#{@location_code}/jobs", params: { page: page}
    jobs["jobs"].each do |job|
      unless self.company_present? job["startup"]["name"]
        p add_company_information job["startup"]
      end
    end
  end

  def add_company_information company
    self.new_companies[company["name"]] = [ company["name"], company["company_url"] ]
  end

  def save_new_companies
    next_row_index = self.companies.length 
    @new_companies.each do |company|
      company[1].each_with_index do |data, index|
        @working_sheet[ next_row_index, index + 1 ] = data
      end
      @working_sheet.save()
      next_row_index +=1
    end
  end

end
@scraper = JobScraper.new "Angelist"
