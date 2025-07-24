#' @return list with:
#' - `actieve_haarden`: a sf - dataframe with observations from gbif.org at more 
#' than 2000m of the nearest managed nest or, if reported closer than 2000m more 
#' than a week after the nest has been managed, thus indicating current activity. 
#' - `onbehandelde_nesten`: a sf - dataframe of nests reported at Vespawatch.be 
#' that have been flagged as not under management or with failed results at more 
#' than 2000m from a managed nest, reported within 2000m at least a week after 
#' the management was concluded succesfully or with current activity reported 
#' within less than 2000m.
#' - `beheerde_nesten`: a sf - dataframe of nests reported at Vespawatch.be 
#' that have been flagged as under management or as managed succesfully.

bereken_actieve_haarden <- function(gbif_data, 
                                    beheer_data,
                                    radii = c(500, 1000, 1500, 2000)){
  
  library(units)
  
  # Inhoud van de kolom result die als "succesvol" beheerd beschouwd wordt
  beheerd <- c("succesvol")
  
  # Split data
  ## Nesten waar nog geen beheer op gestart is of waar het beheer niet succesvol
  ## was
  onbehandelde_nesten <- beheer_data %>% 
    dplyr::filter(!result %in% beheerd) %>% 
    mutate(type = "Onbeheerd Nest",
           actieve_haard = 0) %>% 
    filter(year == year(Sys.Date()))
  
  ## Observaties van individuele hoornaars, voor april zijn waarnemingen koninginnen die ontwaken in woning en worden deze niet meegerekend
  observaties <- gbif_data %>% 
    dplyr::filter(type == "Individu") %>% 
    mutate(actieve_haard = 0,
           month = month(eventDate)) %>% 
    filter(year == year(Sys.Date()),
           month >= 4) 
  
  ## Nesten waar beheer op is uitgevoerd/bezig is.
  beheerde_nesten <- beheer_data %>% 
    dplyr::filter(result %in% beheerd) %>% 
    mutate("type" == "Beheerd Nest") %>% 
    filter(year == year(Sys.Date()))
  
  #onbehandelde_nesten <- gemelde_nesten %>% 
  #dplyr::filter(inaturalist_ids %in% beheerde_nesten$inaturalist_id)
  
  if(nrow(beheerde_nesten)>0){
    actieve_haarden <- data.frame()
    onbehandelde_nesten_sub <- data.frame()
    
    observaties_recomb <- data.frame()
    onbehandelde_nesten_recomb <- data.frame()
    
    # Meldingen van individuen op minder dan 2000m van een beheerd nest gemeld na
    # een actie (succesvol of opgestart)
    for(n in 1:nrow(beheerde_nesten)) {
      # wanneer vond de actie plaats (+2 dagen)
      action_time <- as.Date(beheerde_nesten$observation_time[n]) + 2
      
      # Wat is de afstand tot dit nest?
      beheerd_nest <- beheerde_nesten[n,]
      
      #bereken afstand van behandeld nest tot alle waarnemingen
      observaties$distance <- drop_units(st_distance(observaties, beheerd_nest))
      #bereken afstand van behandeld nest tot alle onbehandelde nesten -> waarom precies deze stap?
      onbehandelde_nesten$distance <- drop_units(st_distance(onbehandelde_nesten, 
                                                             beheerd_nest))
      
      # Gemeld nabij een nest na de beheeractie
      for(r in radii){ 
        #actieve haard van observatie + 1 wanneer individu waargenomen in de buurt na bestrijding
        observaties_rad <- observaties %>% 
          filter(distance <= r) %>% 
          mutate(actieve_haard = case_when(eventDate > 
                                             action_time ~ 
                                             actieve_haard + 1,
                                           eventDate < 
                                             action_time ~
                                             actieve_haard - 1,
                                           TRUE ~ actieve_haard),
                 radius = r)
        
        #actieve haard van onbehandeld nest + 1 wanneer geobserveerd na datum van bestrijding nest (?)
        onbehandelde_nesten_rad <- onbehandelde_nesten %>% 
          filter(distance <= r) %>% 
          mutate(actieve_haard = case_when(observation_time > 
                                             action_time ~ 
                                             actieve_haard + 1,
                                           observation_time < 
                                             action_time ~
                                             actieve_haard - 1,
                                           TRUE ~ actieve_haard),
                 radius = r)
        
        if(nrow(observaties_recomb) == 0){
          observaties_recomb <- observaties_rad
        }else{
          observaties_recomb <- rbind(observaties_recomb, 
                                      observaties_rad)
        }
        
        if(nrow(onbehandelde_nesten_recomb) == 0){
          onbehandelde_nesten_recomb <- onbehandelde_nesten_rad
        }else{
          onbehandelde_nesten_recomb <- rbind(onbehandelde_nesten_recomb, 
                                              onbehandelde_nesten_rad)
        }
      }
    }
    
    actieve_haarden <- observaties_recomb %>% 
      dplyr::filter(actieve_haard >= 1)
    
    onbehandelde_nesten_sub <- onbehandelde_nesten_recomb %>% 
      dplyr::filter(actieve_haard >= 1)
    
    # Voeg meldingen verder dan de radii van een beheerd nest toe aan de 
    #lijst
    rest_obs <- observaties %>% 
      filter(!gbif_ids %in% actieve_haarden$gbif_ids)
    
    rest_nest <- onbehandelde_nesten %>% 
      filter(!id %in% onbehandelde_nesten_sub$id)
    
    pb_obs <- txtProgressBar(min = 0,      # Minimum value of the progress bar
                             max = nrow(rest_obs), # Maximum value of the progress bar
                             style = 3,    # Progress bar style (also available style = 1 and style = 2)
                             width = 50,   # Progress bar width. Defaults to getOption("width")
                             char = "=>")   # Character used to create the bar
    
    for(j in 1:nrow(rest_obs)){
      #wat bereken je hier precies per observatie in rest_obs?
      distance <- drop_units(st_distance(rest_obs[j,], beheerde_nesten))
      for(r in radii){
        if(min(distance) > r){
          rest_obs_sub <- rest_obs[j,] %>% 
            mutate(actieve_haard = 1,
                   radius = r)
          actieve_haarden <- rbind(actieve_haarden, rest_obs_sub)
          setTxtProgressBar(pb, j)
        }
      }
    }
    
    pb_nest <- txtProgressBar(min = 0,      # Minimum value of the progress bar
                              max = nrow(rest_nest), # Maximum value of the progress bar
                              style = 3,    # Progress bar style (also available style = 1 and style = 2)
                              width = 50,   # Progress bar width. Defaults to getOption("width")
                              char = "=>")   # Character used to create the bar
    
    for(j in 1:nrow(rest_nest)){
      #wat bereken je hier precies per nest in rest_nest?
      distance <- drop_units(st_distance(rest_nest[j,], beheerde_nesten))
      for(r in radii){
        if(min(distance) > r){
          
          rest_nest_sub <- rest_nest[j,] %>% 
            mutate(radius = r)
          
          if(nrow(onbehandelde_nesten_sub) == 0){
            onbehandelde_nesten_sub <- rest_nest_sub
          }else{
            onbehandelde_nesten_sub <- rbind(onbehandelde_nesten_sub, 
                                             rest_nest_sub)
          }
        }
      }
      setTxtProgressBar(pb, j)
    }
    
    # Voeg onbehandelde nesten met actieve haard op minder dan 2000m toe 
    rest_nest <- onbehandelde_nesten %>% 
      filter(!id %in% onbehandelde_nesten_sub$id)
    
    for(j in 1:nrow(rest_nest)){
      distance <- drop_units(st_distance(rest_nest[j,], actieve_haarden))
      for(r in radii){
        
        rest_nest_sub <- rest_nest[j,] %>% 
          mutate(radius = r)
        
        if(min(distance) < r){
          if(nrow(onbehandelde_nesten_sub) == 0){
            onbehandelde_nesten_sub <- rest_nest_sub
          }else{
            onbehandelde_nesten_sub <- rbind(onbehandelde_nesten_sub, 
                                             rest_nest_sub)
          }
        }
      }
    }
    
    return(list(actieve_haarden = actieve_haarden,
                onbehandelde_nesten = onbehandelde_nesten_sub,
                beheerde_nesten = beheerde_nesten))
  }else{
    actieve_haarden <- data.frame(
      eventDate = character(),
      year = integer(),
      type = character(),
      level1Name = character(),
      level2Name = character(),
      level3Name = character(),
      popup = logical(),
      inaturalist_ids = character(),
      gbif_ids = character(),
      institutionCode = character(),
      actieve_haard = logical(),
      distance = numeric(),
      geometry = character())
    return(list(actieve_haarden = actieve_haarden,
                onbehandelde_nesten = nesten,
                beheerde_nesten = beheerde_nesten))
  }
}