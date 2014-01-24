you can use this to scrape angel list jobs for companies that are seeking in san francisco, pull the company and url into google doc
```
  @scraper = JobScraper.new "SheetName"
```

ENV["JOBS_SPREADSHEET"] should be the key taken from a google docs spreadsheet 

https://docs.google.com/spreadsheet/ccc?key=0AgNKgCBuP1RZXNVb3Juoxd3Fla3VZQm1TQmc

"SheetName" should be the actual name of the sheet you want to use
