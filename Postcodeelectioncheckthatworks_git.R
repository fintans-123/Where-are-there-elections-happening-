## SCRIPT FOR COLLECTING POSTCODE INFORMATION FOR AREAS UP FOR ELECTION
# This script plugs into the Electoral Commission API and will query individual postcodes drawn from a list, returning a boolean value stored in a list. 



library(pacman)

p_load(tidyverse,openxlsx,stringr)



postcode <- read_csv("NSPL21_FEB_2024_UK.csv")



postcode_clean<- postcode%>%
  mutate(pcd= str_replace_all(pcd, fixed(" "), ""))%>%
  mutate(first_two= substr(pcd,start=1,stop=2))%>%
  filter(!str_detect(first_two,"AB"))%>%  ## Remove Scottish postcodes minus Glasgow
  filter(!str_detect(first_two,"BT"))%>%
  filter(!str_detect(first_two,"DD"))%>%
  filter(!str_detect(first_two,"DG"))%>%
  filter(!str_detect(first_two,"EH"))%>%
  filter(!str_detect(first_two,"FK"))%>%
  filter(!str_detect(first_two,"BT"))%>%
  filter(!str_detect(first_two,"HS"))%>%
  filter(!str_detect(first_two,"HS"))%>% 
  filter(!str_detect(first_two,"IV"))%>%
  filter(!str_detect(first_two,"KA"))%>% 
  filter(!str_detect(first_two,"KY"))%>%
  filter(!str_detect(first_two,"PA"))%>%
  filter(!str_detect(first_two,"TD"))%>% 
  filter(!str_detect(first_two,"ZE"))



postcode_cleaner<- postcode_clean%>%
  group_by(ward)%>%
  summarise(pcd= sample(pcd,2,replace=TRUE)) ## Randomly pick two postcodes for every ward

  
  postcode_lookup <- postcode_cleaner$pcd



# please request your own token to do work pulling from EC api here:https://api.electoralcommission.org.uk/user/login/
  token <- "GET A TOKEN FROM EC AND PASTE HERE"


check_elections <- function(postcode, token) {
  url1 <- paste0("https://api.electoralcommission.org.uk/api/v1/postcode/", postcode)  
  
  postcode_res <- GET(url1,
                      add_headers("Authorization" = paste("Bearer", token)))
  
  data_one <- fromJSON(rawToChar(postcode_res$content))
  
  if (!is.null(data_one$error)) {
    return("ERROR")
  }
  
  if("address_picker" %in% names(data_one)){
  
  if (data_one$address_picker==TRUE) {
    address <- data_one$addresses[1,]
    new_url <- address$url
    res <- GET(new_url,
               add_headers("Authorization" = paste("Bearer", token)))
    data <- fromJSON(rawToChar(res$content))
    data <- data$dates
    dtf_ballot <- as.data.frame(data$ballots)
  } else{
    
    # Assuming dtf_ballot is defined somewhere in your code
    data <- data_one$dates
    dtf_ballot <- as.data.frame(data$ballots)}
  
  
  # Check if any elections are happening on 2024-05-02
  date_yn <- "2024-05-02" %in% dtf_ballot$poll_open_date
  
  # Check if any of the election types match
  type_election_mayoral <- any(grepl("Mayor", dtf_ballot$ballot_title, ignore.case = TRUE)) ## FOR FUTURE USERS: Edit these conditions
  type_election_assembly <- any(grepl("assembly", dtf_ballot$ballot_title, ignore.case = TRUE))
  type_election_local <- any(grepl("local", dtf_ballot$ballot_title, ignore.case = TRUE))
  
  if (date_yn & (type_election_mayoral | type_election_assembly | type_election_local)) {
    return(TRUE)  
  } else {
    return(FALSE)
  }
  } 
}


# looping through each postcode
for (postcode in postcode_lookup) {
  elections <- check_elections(postcode, token) # Elections object ends up being either Boolean, or marked 'ERROR'
  cat("Elections in", postcode, ":", elections, "\n")  
  results[[postcode]] <- elections
}



# Wrangle output ------------------------------------------------------------

result_df <- as.data.frame(results)

long_df <- result_df %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column(var = "pcd") %>%
  pivot_longer(cols = -pcd, 
               names_to = "var", 
               values_to = "local_or_mayoral")

long_df_todedupe <- left_join(postcode_cleaner,long_df, by="pcd",relationship="many-to-many")

## This is clunky, but basically we group the two sample postcodes by ward and then if TRUE or FALSE appears for either of the two
## postcodes sampled, we give both of them a value of TRUE or FALSE. We can then de-duplicate.


long_df_dedupe <- long_df_todedupe %>%
  group_by(ward) %>%
  mutate(final = ifelse(any(grepl("TRUE", local_or_mayoral)), "TRUE", local_or_mayoral))%>%
  mutate(final = ifelse(any(grepl("FALSE", local_or_mayoral)), "FALSE", final))%>%
  distinct(ward,.keep_all = TRUE)



# Join output with ward ---------------------------------------------------

final_result_postcode <- left_join(postcode_clean,long_df_dedupe,by="ward",relationship="many-to-many")%>%
  select(ward,pcd.x,cty,local_or_mayoral,final)

final_eligible_post_code <- final_result_postcode%>%
  filter(final=="TRUE")%>%
  select(pcd.x)

write.csv(final_eligible_post_code,"final_post_code.csv")



# Reduce to first half of postcode ----------------------------------------


first_half_pcd <- final_eligible_post_code%>%
  mutate(first_half_pcd = substr(pcd.x,start=1,nchar(pcd.x)-3))%>%
  distinct(first_half_pcd)

write.csv(first_half_pcd,"for_target.csv")
