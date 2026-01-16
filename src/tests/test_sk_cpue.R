test <- cleanData %>% 
  group_by(eventID, year) %>% 
  summarise(effort = max(n_fuiken, na.rm= TRUE),
            individualCount = sum(individualCount, na.rm = TRUE),
            cpue = individualCount/effort) %>% 
  group_by(year) %>% 
  summarise(individualCount = sum(individualCount, na.rm = TRUE),
            effort = sum(effort, na.rm = TRUE),
            cpue = individualCount/effort)

table(cleanData$gemeente)


test2 <- cleanData %>% 
  filter(eventID == "01-06-2017_scheps 8")

test3 <- rawData %>% 
  filter(eventID == "01-06-2017_scheps 8")

"01-06-2021_laakdal 41"
"01-07-2025_anthei 0647"
"01-06-2021_griesbroek 6"
"01-06-2017_scheps 8"