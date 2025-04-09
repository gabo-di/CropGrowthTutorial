"""
    calibrate_phenology_parameters!(crop_dict, crop_name; kw...)

changes a phenology-precalibrated crop_dict with the calibrated crop parameters related to root and canopy growth 
"""
function calibrate_canopy_root_parameters!(crop_dict, crop_name; kw...)
    # setup the crop since we need some parameters of it
    crop = AquaCrop.RepCrop()
    AquaCrop.set_crop!(crop, crop_name; aux = nothing)

    flow_old = crop.GDDaysToFlowering
    harv_old = crop.GDDaysToHarvest
    flow_new = crop_dict["GDDaysToFlowering"]
    harv_new = crop_dict["GDDaysToHarvest"]

    # note that we assume that crop.CCx remains the same
     
    # adjust time to senescence
    target_old = crop.GDDaysToSenescence
    crop_dict["GDDaysToSenescence"] = proportional_adjust(flow_old, harv_old, flow_new, harv_new, target_old)

    # adjust canopy decay coefficient
    crop_dict["GDDCDC"] = cdc_adjust(crop, crop_dict)
     
    # adjust time to full canopy cover
    target_old = time_to_full_canopy(crop, crop_dict)
    crop_dict["GDDaysToFullCanopy"] = proportional_adjust(flow_old, harv_old, flow_new, harv_new, target_old)

    # adjust canopy growth coefficient
    crop_dict["GDDCGC"] = cgc_adjust(crop, crop_dict)

    # adjust time to maxrooting 
    target_old = crop.GDDaysToMaxRooting
    crop_dict["GDDaysToMaxRooting"] = proportional_adjust(flow_old, harv_old, flow_new, harv_new, target_old)

    # adjust of root max
    crop_dict["RootMax"] = crop.RootMax 
    
    return nothing
end

function proportional_adjust(flow_old, harv_old, flow_new, harv_new, target_old)
    target_new = (harv_new - flow_new) * (target_old - flow_old)/ (harv_old - flow_old) + flow_new
    return round(Int,target_new)
end

function time_to_full_canopy(crop::AquaCrop.RepCrop, crop_dict)
    # based on AquaCrop.days_to_reach_cc_with_given_cgc and AquaCrop.time_to_max_canopy_sf
    ccxval = crop.CCx
    cgcval_old = crop.GDDCGC
    ccoval = crop_dict["PlantingDens"]/10000 * crop.SizeSeedling/10000
    ltogermination_old = crop.GDDaysToGermination

    cctoreach_local = 0.98*ccxval
    return log((0.25*ccxval*ccxval/ccoval)/(ccxval-cctoreach_local))/(cgcval_old) + ltogermination_old
end

function cdc_adjust(crop::AquaCrop.RepCrop, crop_dict)
    # based on AquaCrop.length_canopy_decline
    ltoharvest = crop_dict["GDDaysToHarvest"]
    ltosenescence = crop_dict["GDDaysToSenescence"]
    ccxval = crop.CCx

    nd = ltoharvest - ltosenescence
    cdcval = ((ccxval+2.29)/((nd)*3.33))*log(1 + 1/0.05)

    return cdcval
end

function cgc_adjust(crop::AquaCrop.RepCrop, crop_dict)
    # based on AquaCrop.days_to_reach_cc_with_given_cgc and AquaCrop.time_to_max_canopy_sf
    ccxval = crop.CCx
    cctoreach_local = 0.98*ccxval
    ccoval = crop_dict["PlantingDens"]/10000 * crop.SizeSeedling/10000
    l12sf_new = crop_dict["GDDaysToFullCanopy"]
    ltogermination_new = crop_dict["GDDaysToGermination"]

    cgcval = log((0.25*ccxval*ccxval/ccoval)/(ccxval-cctoreach_local))/(l12sf_new - ltogermination_new)
    return cgcval
end
