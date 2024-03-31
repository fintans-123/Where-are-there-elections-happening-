# Where-are-there-elections-happening-

The script in this repo plugs into the Electoral Commission API and will query individual postcodes drawn from a list, returning a boolean value stored in a list. To use it, you need to create an account at https://api.electoralcommission.org.uk/user/login/ and then assign your token to the 'token' object. I used a list of postcodes from the UK national statistics postcode lookup to generate the list, here: https://geoportal.statistics.gov.uk/datasets/9ac0331178b0435e839f62f41cc61c16.

To query every postcode via this method would take you about four weeks and fry your computer, so instead this script groups by the relevant geography and then randomly samples two postcodes for each. The EC database is incomplete in places, or does not have postcodes stored for defunct postcodes still in the NSPL, hence we sample two for each to minimise error.
