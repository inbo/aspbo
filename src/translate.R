  translate <- function(){
    library(tidyverse)
    library(svDialogs)
    
    translations <- read_delim("alienSpecies/inst/extdata/translations.csv", 
                               delim = ";", escape_double = FALSE, trim_ws = TRUE)
    
    missing_translations <- translations %>% 
      filter(!is.na(title_id)) 
    
    missing_translations_en <- missing_translations %>% 
      filter(is.na(title_en)) %>% 
      dplyr::select(title_id, title_en)
    
    missing_translations_fr <- missing_translations %>% 
      filter(is.na(title_fr))  %>% 
      dplyr::select(title_id, title_fr)
    
    
    missing_translations_nl <- missing_translations %>% 
      filter(is.na(title_nl)) %>% 
      dplyr::select(title_id, title_nl)
    
    
    for(mtnl in 1:nrow(missing_translations_nl)){
      title_id <- missing_translations_nl[mtnl,]$title_id
      
      transl <- dlgInput(message = paste0("translate ", title_id, " into NL"),
                         default = NA_character_)$res
      
      if(is_character(transl) && !is_empty(transl)){
        missing_translations_nl[mtnl,2] <- transl
      }else{
        next
      }
    }
    
    for(mten in 1:nrow(missing_translations_en)){
      title_id <- missing_translations_en[mten,]$title_id
      
      transl <- dlgInput(message = paste0("translate ", title_id, " into EN"),
                         default = NA_character_)$res
      
      if(is_character(transl) && !is_empty(transl)){
        missing_translations_en[mten,2] <- transl
      }else{
        next
      }
    }
    
    for(mtfr in 1:nrow(missing_translations_fr)){
      title_id <- missing_translations_fr[mtfr,]$title_id
      
      transl <- dlgInput(message = paste0("translate ", title_id, " into FR"),
                         default = NA_character_)$res
      
      if(is_character(transl) && !is_empty(transl)){
        missing_translations_fr[mtfr,2] <- transl
      }else{
        next
      }
    }
    
    translations <- translations %>% 
      left_join(missing_translations_nl, by = "title_id") %>% 
      mutate(title_nl = case_when(!is.na(title_nl.y) ~ title_nl.y,
                                  !is.na(title_nl.x) ~ title_nl.x,
                                  TRUE ~ NA_character_)) %>% 
      dplyr::select(-contains("title_nl.")) %>% 
      left_join(missing_translations_en, by = "title_id") %>% 
      mutate(title_en = case_when(!is.na(title_en.y) ~ title_en.y,
                                  !is.na(title_en.x) ~ title_en.x,
                                  TRUE ~ NA_character_)) %>% 
      dplyr::select(-contains("title_en.")) %>% 
      left_join(missing_translations_fr, by = "title_id") %>% 
      mutate(title_fr = case_when(!is.na(title_fr.y) ~ title_fr.y,
                                  !is.na(title_fr.x) ~ title_fr.x,
                                  TRUE ~ NA_character_)) %>% 
      dplyr::select(-contains("title_fr."))
    
    write_delim(translations, "alienSpecies/inst/extdata/translations.csv", 
                delim = ";", escape_double = FALSE, trim_ws = TRUE)
  }
