#=
GET RAW DATA

This is an example repository showing you how to download data from the ECMWF Climate Data Store (CDS) using the CDS API.

As described in the documentation (https://github.com/JuliaClimate/CDSAPI.jl) You will need an API key stored on a file.
See https://cds.climate.copernicus.eu/api-how-to for instructions.

We will use data from the ERA5 reanalysis project.
A reanalysis is a gridded reconstruction of historical weather data using a fixed data assimilation system.
In essence, it combines a model and observations to reconstruct the entire state of the Earth system at a given time.

All the data we will use falls into two categories:

- reanalysis-era5-single-levels: this is for data that does not vary in the vertical dimension. Surface temperature is an example.
- reanalysis-era5-pressure-levels: this is for data that varies in the vertical dimension. Geopotential height is an example.

The following script provides you with a function to download data from both categories.
We download data one year at a time to avoid creating files that are too large.

You may want to modifty some of the arguments

- time: the functions below provide hourly data. You can modify to store only a single hour per day by setting this to "2:00" for example. Daily data is not available, but you can download hourly data and average it yourself.
- area: the area of interest. The default roughly spans the continental US, but you can modify
- grid: the grid resolution. The default is 1 degree, but you can modify to increase or lower resolution
- pressure_level: only used for pressure level data. Here we use 500 hPa, but you can modify to download data at other levels.

For more documentation, visit
https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=overview
https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=overview
for more information.
At this website, you can generate your own API calls using the web interface (click the Download data tab).
At the bottom of the page, click Show API request.
You can copy and paste this into the CDSAPI.py2ju function below.

Some advice so that you can avoid mistakes I have made

- it can take a while for the system to load your data request, especially if you are requesting a lot of data. You can track your requests at https://cds.climate.copernicus.eu/cdsapp#!/yourrequests (look at queued/in progress). Be patient
- Make sure that you set the format to netcdf, otherwise you will get grib data which is a pain to deal with
- Don't modify your raw data, because re-downloading it is annoying (although the second time will be faster -- they temporarily cache things on the servers). Instead, keep your raw data pristine and create a new file with your modifications. I suggest putting these modifications (eg, hourly to daily; spatial averaging; removing anomalies; combining multiple files; etc) in a separate script, perhaps called `process_data.jl`
- If you want to use Python for downloading and/or processing your data, you may. https://docs.xarray.dev/en/stable/ is a great and stable tool with excellent documentation. However, I will not troubleshoot your Python code, so you're on your own.
- Use `abspath` to make sure that your files are saved in the right place. You can also use `joinpath` to make sure that your file paths are correct on different operating systems.
- Make sure you understand this template code! Use AI tools and ask questions as needed.
=#
using CDSAPI

# find the "root" directory of your project
HOMEDIR = abspath(dirname(@__FILE__))

function download_single_level_data(year::Int, filename::String, variable::String)
    if isfile(filename)
        println("File $filename already exists. Skipping download.")
        return nothing
    end

    return CDSAPI.retrieve(
        "reanalysis-era5-single-levels",
        CDSAPI.py2ju("""{
                     "product_type": "reanalysis",
                     "format": "netcdf",
                     "variable": "$variable",
                     "year": "$year",
                     "month": $(["$(lpad(i, 2, '0'))" for i in 1:12]),
                     "day": $(["$(lpad(i, 2, '0'))" for i in 1:31]),
                     "time": $(["$(lpad(i, 2, '0')):00" for i in 0:23]),
                     "area": [50, -130, 24, -65],
                     "grid": ["1.0", "1.0"],
                     }"""),
        filename,
    )
end

function download_pressure_level_data(
    year::Int, filename::String, variable::String, level::Int
)
    if isfile(filename)
        println("File $filename already exists. Skipping download.")
        return nothing
    end

    return CDSAPI.retrieve(
        "reanalysis-era5-pressure-levels",
        CDSAPI.py2ju("""{
                     "product_type": "reanalysis",
                     "format": "netcdf",
                     "variable": "$variable",
                     "pressure_level": "$level",
                     "year": "$year",
                     "month": $(["$(lpad(i, 2, '0'))" for i in 1:12]),
                     "day": $(["$(lpad(i, 2, '0'))" for i in 1:31]),
                     "time": $(["$(lpad(i, 2, '0')):00" for i in 0:23]),
                     "area": [50, -130, 24, -65],
                     "grid": ["1.0", "1.0"],
                     }"""),
        filename,
    )
end

function download_year_data(year::Int)
    data_dir = joinpath(HOMEDIR, "data", "raw")

    # Download 2m air temperature for the year 2020
    # this file is 31.3 MB, for your reference
    download_single_level_data.(
        year, joinpath(data_dir, "2m_temperature_$year.nc"), "2m_temperature"
    )

    # Download 500 hPa geopotential for the year 2020
    # this file is 31.3 MB, for your reference
    download_pressure_level_data.(
        year, joinpath(data_dir, "500hPa_geopotential_$year.nc"), "geopotential", 500
    )

    return true
end

function main()
    years = 2019:2020
    for year in years
        download_year_data(year)
    end
    return true
end

main()