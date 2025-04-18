#############
# constants #
#############
climate_data_dir = "exp_raw"
yield_data_dir = "exp_raw"
phenology_data_dir = "exp_raw"

#####################
# utility functions #
#####################
function rename_cols!(df::AbstractDataFrame)
    rename!(df, [col => lowercase(col) for col in names(df)])
    return nothing
end

function drop_cols!(df::AbstractDataFrame)
    select!(df, Not(r"eor", r"Column"))
end

function preprocess_df!(df::AbstractDataFrame)
    drop_cols!(df)
    rename_cols!(df)
    return nothing
end

function head(df::AbstractDataFrame)
    n_lines = 5
    first(df, n_lines)
end

#################
# api functions #
#################
"""
    df = get_climate_data(station_name)

reads the climate data from the climate file
"""
function get_climate_data(station_name::AbstractString)
    hk_clim_path = "weather_" * station_name * ".csv"
    keep_cols = [:date, :precipitation, :max_temperature, :min_temperature, :potential_evapotranspiration];
    file_name = datadir(climate_data_dir, hk_clim_path)
    if isfile(file_name)
        hk_clim_df  = CSV.read(file_name, DataFrame;
                            stripwhitespace=true,
                            delim=",",
                            missingstring="NA",
                            select=(i, name) -> name in keep_cols,
                            dateformat = DateFormat("yyyy-mm-dd"),
                            types=(i, name) -> name==:date ? Date : Float64 );
        date_eto = Date(1992, 1, 1);
        filter!(row -> row.date >= date_eto, hk_clim_df);
        return coalesce.(hk_clim_df, 0.0);
    else
        return nothing
    end
end

"""
    list_climate_files()

list all the climate files
"""
function list_climate_files()
    v = readdir(datadir(climate_data_dir)) 
    for vv in v
        if startswith(vv, "weather_")
            println(vv)
        end
    end
    return nothing
end

"""
    df = get_yield_data(station_name)

reads the yield data from the yield file
"""
function get_yield_data(station_name::AbstractString)
    hk_yield_path = "yield_data_" * station_name * ".csv"
    file_name = datadir(yield_data_dir, hk_yield_path)
    if isfile(file_name)
        return CSV.read(file_name, DataFrame;
                                  stripwhitespace=true,
                                  delim=",",
                                  missingstring="NA",
                                  ignorerepeated=true
                                  );
    else
        return nothing
    end
end

"""
    list_yield_data_files()

list all the yield files
"""
function list_yield_data_files()
    v = readdir(datadir(yield_data_dir)) 
    for vv in v
        if startswith(vv, "yield_data_")
            println(vv)
        end
    end
    return nothing
end

"""
    df = get_crop_phenology_data(crop_name, station_name)

reads the phenology data for a given crop and a given station
if called with station::String then uses the data from `get_phenology_stations`
"""
function get_crop_phenology_data(crop_name::AbstractString)
    cropfile = "phenology_" * crop_name * ".csv"
    file_name = datadir(phenology_data_dir, cropfile)
    if isfile(file_name)
        df = CSV.read(file_name, DataFrame, normalizenames=true, stripwhitespace=true)
        preprocess_df!(df)
        return df
    else
        return nothing
    end
end

function get_crop_phenology_data(cropfile::AbstractString, station::Int)
    df = get_crop_phenology_data(cropfile)
    if isnothing(df)
        return df
    end
    gb = groupby(df, :stations_id)
    if haskey(gb, (station,))
        return gb[(station,)]
    else
        return nothing
    end
end

function get_crop_phenology_data(cropfile::AbstractString, station::AbstractString)
    st = get_phenology_stations(station)
    if isnothing(st)
        return st 
    end
    station_i = st[1,:stations_phenology_id]

    get_crop_phenology_data(cropfile, station_i)
end



"""
    list_phenology_data_files()

list all the phenology files
"""
function list_phenology_data_files()
    v = readdir(datadir(phenology_data_dir)) 
    for vv in v
        if startswith(vv, "phenology_")
            println(vv)
        end
    end
    return nothing
end

"""
    df = get_phenology_stations_dict()

returns a dataframe with the phenology stations name and ids
"""
function get_phenology_stations()
    file_name = datadir("exp_raw","cap4gi_stations.csv")
    CSV.read(file_name, DataFrame)
end

function get_phenology_stations(I::Int)
    df = get_phenology_stations()
    gb = groupby(df, :stations_phenology_id)
    if haskey(gb, (I,))
        return gb[(I,)]
    else
        return nothing
    end
end

function get_phenology_stations(I::AbstractString)
    df = get_phenology_stations()
    gb = groupby(df, :station_name)
    if haskey(gb, (I,))
        return gb[(I,)]
    else
        return nothing
    end
end

function get_all_phenology_stations()
    df = CSV.read(datadir(phenology_data_dir,"observation_stations.csv"), DataFrame)
    preprocess_df!(df)
    return df
end

function get_all_phenology_phases()
    return CSV.read(datadir(phenology_data_dir,"phase_descriptions.csv"), DataFrame)
end

"""
    df = get_crop_default_parameters()

returns the crop's default paraemeters except for sowingdensity
"""
function get_crop_parameters()
    CSV.read(datadir("exp_raw","crop_data_general.csv"), DataFrame)
end
