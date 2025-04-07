##########################
# crop growth simulation #
##########################
"""
    get_co2_data(fromdaynr, todaynr)

here we get the data for co2 for a given year
"""
function get_co2_data(fromdaynr, todaynr)
    # the co2 data is in this csv inside AquaCrop.jl
    co2_file = joinpath(AquaCrop.test_toml_dir, "MaunaLoaCO2.csv")
    co2 = AquaCrop.co2_for_simulation_period(co2_file, fromdaynr, todaynr)
    return co2
end

"""
    run_simulation(soil_type, crop_type, crop_type_df, year_crop, general_crop_data, hv_clim_df; kw...)

here we run the AquaCrop simulation, note that depending on the version of AquaCrop.jl we might need to change this file

`kw[:outdaily]::Bool` gives if we want a daily output or not. Defaults to AquaCrop.jl default value
`kw[:crop_dict]::Dict` gives additional information about the crop, passed directly to AquaCrop.jl

"""
function run_simulation(soil_type, crop_type, crop_date, hv_clim_df; kw...)

    start_date = crop_date - days_before_sowing 
    end_date = start_date + days_after_sowing 
    if (start_date<hv_clim_df[1,:date]) | (end_date>hv_clim_df[end,:date])
        all_ok = AquaCrop.AllOk(false," missing clim data")
        return nothing, all_ok
    end

    clim_df = filter(row -> end_date>=row.date>=start_date, hv_clim_df, view=true)

    epot_v = haskey(kw, :epot_v) ? kw[:epot_v] : 1
    rain_v = haskey(kw, :rain_v) ? kw[:rain_v] : 1
    temp_v = haskey(kw, :temp_v) ? kw[:temp_v] : 0
    dens_v = haskey(kw, :dens_v) ? kw[:dens_v] : 1
    gdtm_v = haskey(kw, :gdtm_v) ? kw[:gdtm_v] : 0
    gcgc_v = haskey(kw, :gcgc_v) ? kw[:gcgc_v] : 1

    if haskey(kw, :crop_dict)
        _crop = kw[:crop_dict]
        if haskey(_crop, "PlantingDens")
            _crop["PlantingDens"] = round(Int, _crop["PlantingDens"]*dens_v)
        end
        if haskey(_crop, "GDtranspLow")
            _crop["GDtranspLow"] += gdtm_v
        end
        if haskey(_crop, "GDDCGC")
            _crop["GDDCGC"] *= gcgc_v
        end
    end



    # Generate the keyword object for the simulation
    kwargs = (

        ## Necessary keywords

        # runtype
        runtype = NoFileRun(),

        # project input
        Simulation_DayNr1 = start_date,
        Simulation_DayNrN = end_date,
        Crop_Day1 = start_date + days_before_sowing,
        Crop_DayN = end_date,

        # soil
        soil_type = soil_type,

        # crop
        crop_type = crop_type,

        # Climate
        InitialClimDate = start_date,



        ## Optional keyworkds

        # Climate
        Tmin = clim_df.min_temperature .+ temp_v,
        Tmax = clim_df.max_temperature .+ temp_v,
        ETo = clim_df.potential_evapotranspiration .* epot_v,
        Rain = clim_df.precipitation .* rain_v,

    )

    # change crop properties
    if haskey(kw, :crop_dict)
        kwargs = merge(kwargs, (crop = _crop,))
    end

    # start cropfield
    cropfield, all_ok = start_cropfield(; kwargs...)
    if !isequal(all_ok.logi, true)
        # @infiltrate
        return nothing, all_ok
    end

    # setup cropfield
    # setup_cropfield!(cropfield, all_ok; kwargs...)
    # isequal(all_ok.logi, true)
    if haskey(kw, :outdaily)
        outdaily = kw[:outdaily]
        AquaCrop.setparameter!(cropfield.gvars[:bool_parameters], :outdaily, outdaily)
    end

    # run cropfield
    season_run!(cropfield)

    # write GDD
    x = sum(cropfield.dayout.GD[1:days_before_sowing.value])
    cropfield.dayout[!,"GDD"] = cumsum(cropfield.dayout.GD) .- x

    return cropfield, all_ok
end

"""
    df, crop = run_cropgdd(crop_type, start_date, end_date, hv_clim_df; kw...)

for a given `crop_type`, climate and dates returns the growing degree days
"""
function run_cropgdd(crop_type, start_date, end_date, hv_clim_df; kw...)
    # see if we have climate data for the interval of dates
    if (start_date<hv_clim_df[1,:date]) | (end_date>hv_clim_df[end,:date])
        all_ok = AquaCrop.AllOk(false," missing clim data")
        return nothing, all_ok
    end
    clim_df = filter(row -> end_date>=row.date>=start_date, hv_clim_df, view=true)

    # setup the crop since we need some parameters of it
    crop = AquaCrop.RepCrop()
    AquaCrop.set_crop!(crop, crop_type; aux = haskey(kw, :crop_dict) ? kw[:crop_dict] : nothing)
    # note that the code run even if a wrong crop type is passed, since it gives the default crop
    tbase = crop.Tbase
    tupper = crop.Tupper
    gddselectedmethod = 3 # default value for simulparam.GDDMethod


    gdd = cumsum(map( (x,y) -> AquaCrop.degrees_day(tbase, tupper, x, y, gddselectedmethod),
            clim_df.min_temperature,
            clim_df.max_temperature))

    return DataFrame(date=clim_df[:,:date], GDD = gdd), crop
end
