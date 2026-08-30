#' assign dutch article
#' 
#' @description
#' A function that tries to assign the correct article to the dutch vernacular name.
#' This result can be overwritten by adding the gbif nubKey to the relevant exception list
#' 
#' @param species_data df with the vernacular_name_nl & nubKey 
#' @param het_exception species which article is "het" in contradiction of the rules
#' @param de_exception species which article is "de" in contradiction of the rules
#' 
#' @details
#' Add a $ at the end of an exception to make sure the string is detected at the 
#' end of the name.
#' 
#' 
#' @return the input df with a new column article_nl containing the article 
#' according to grammar rules and exception lists. 


assign_dutch_article <- function(
    species_data, 
    het_exception = c(),  # vector of nubKey for known "het" exceptions
    de_exception = c()    # vector of nubKey for known "de" exceptions
) {
  species_data$article_nl <- NA
  
  for (i in seq_len(nrow(species_data))) {
    row <- species_data[i, ]
    name <- tolower(row$vernacular_name_nl)
    nubkey <- row$nubKey
    
    # Hardcoded exceptions by nubKey override all rules
    if (nubkey %in% het_exception) {
      species_data$article_nl[i] <- "het"
      next
    }
    if (nubkey %in% de_exception) {
      species_data$article_nl[i] <- "de"
      next
    }
    
    if (row$kingdom == "Animalia") {
      # Most animal species get "de"
      # Small set of animal exceptions for "het"
      het_animal_exceptions <- c("kalf$", "lam$", "varken$", "paard$", "jong$", "hert$")
      if (any(sapply(het_animal_exceptions, function(x) grepl(x, name)))) {
        species_data$article_nl[i] <- "het"
      } else {
        species_data$article_nl[i] <- "de"
      }
      
    } else if (row$kingdom == "Plantae") {
      # Plants mostly get "de" but "het" for diminutives and certain keywords
      het_suffixes <- c("je$", "tje$", "pje$", "etje$", "mpje$")
      het_keywords <- c("blad$", "gewas$")
      
      is_het <- any(sapply(het_suffixes, function(suf) grepl(paste0(suf, "$"), name))) ||
        any(sapply(het_keywords, function(k) grepl(k, name)))
      
      species_data$article_nl[i] <- ifelse(is_het, "het", "de")
      
    } else {
      # Default fallback
      species_data$article_nl[i] <- "de"
    }
  }
  
  return(species_data)
}
