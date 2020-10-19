#!/bin/bash
##      .SYNOPSIS
##      Grafana Dashboard for Wordpress.com Jetpack - Using RestAPI to InfluxDB Script
## 
##      .DESCRIPTION
##      This Script will query the Wordpress.com Jetpack RestAPI and send the data directly to InfluxDB, which can be used to present it to Grafana. 
##      The Script and the Grafana Dashboard it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  wordpress_grafana.sh
##      ORIGINAL NAME: wordpress_grafana.sh
##      LASTEDIT: 19/10/2020
##      VERSION: 1.1
##      KEYWORDS: Wordpress, InfluxDB, Grafana
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

##
# Configurations
##
# Endpoint URL for InfluxDB
InfluxDBURL="YOURINFLUXSERVERIP" #Your InfluxDB Server, http://FQDN or https://FQDN if using SSL
InfluxDBPort="8086" #Default Port
InfluxDB="telegraf" #Default Database
InfluxDBUser="USER" #User for Database
InfluxDBPassword="PASSWORD" #Password for Database - Remove this from the script if you do not have password (not recommended)

# Endpoint URL for login action
WPSiteURL="YOURSITE" #Without HTTP or HTTPS, so for example www.jorgedelacruz.es
WPAuthBearer='YOURBEARERCODE' #It is important to respect the single quote as the WP token might include really weird characters

##
# Wordpress.com Jetpack Stats - Default Query to obtain general information about our Site
##
WPAPIURL="https://public-api.wordpress.com/rest/v1.1/sites/$WPSiteURL/stats?http_envelope=1&"
WPAPIStatsURL=$(curl -X GET --header "Accept:application/json" --header 'Authorization:Bearer '$WPAuthBearer'' "$WPAPIURL" 2>&1 -k --silent)

    WPAPIStatsTotalVisitors=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.visitors")
    WPAPIStatsTotalViews=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.views")        
    WPAPIStatsBestDay=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.views_best_day_total")        
    WPAPIStatsTotalComments=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.comments")       
    WPAPIStatsTotalPosts=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.posts")
    WPAPIStatsTotalFollowers=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.followers_blog")        
    WPAPIStatsTotalFollowersComments=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.followers_comments")        
    WPAPIStatsTotalComments=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.stats.comments")
    WPAPIStatsDate=$(echo "$WPAPIStatsURL" | jq --raw-output ".body.date")
    WPAPIStatsDateTime="T00:00:00Z"
    WPAPIStatsDateFinal=$(echo $WPAPIStatsDate$WPAPIStatsDateTime)
    WPAPIStatsTimeStamp=`date -d "${WPAPIStatsDateFinal}" '+%s'`

    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "wordpress_api_stats,site=$WPSiteURL totalvisitors=$WPAPIStatsTotalVisitors,totalviews=$WPAPIStatsTotalViews,bestday=$WPAPIStatsBestDay,totalcomments=$WPAPIStatsTotalComments,totalposts=$WPAPIStatsTotalPosts,totalfollowers=$WPAPIStatsTotalFollowers,totalfollowerscomments=$WPAPIStatsTotalFollowersComments,totalcomments=$WPAPIStatsTotalComments $WPAPIStatsTimeStamp"
        
##
# Wordpress.com Jetpack Daily Stats - Default Query to obtain last x days (by default 30)
##
WPAPIDays="30"
WPAPIURL="https://public-api.wordpress.com/rest/v1.1/sites/$WPSiteURL/stats?unit=day&quantity=$WPAPIDays&http_envelope=1&"
WPAPIDailyStatsURL=$(curl -X GET --header "Accept:application/json" --header 'Authorization:Bearer '$WPAuthBearer'' "$WPAPIURL" 2>&1 -k --silent)

declare -i arraydaily=0
for row in $(echo "$WPAPIDailyStatsURL" | jq -r '.body.visits.data[][1]'); do
    WPAPIStatsDailyViews=$(echo "$WPAPIDailyStatsURL" | jq --raw-output ".body.visits.data[$arraydaily][1]")  
    WPAPIStatsDailyVisitors=$(echo "$WPAPIDailyStatsURL" | jq --raw-output ".body.visits.data[$arraydaily][2]")
    WPAPIStatsDailyDate=$(echo "$WPAPIDailyStatsURL" | jq --raw-output ".body.visits.data[$arraydaily][0]")
    WPAPIStatsDailyDateTime="T00:00:00Z"
    WPAPIStatsDailyDateFinal=$(echo $WPAPIStatsDailyDate$WPAPIStatsDailyDateTime)
    WPAPIStatsDailyTimeStamp=`date -d "${WPAPIStatsDailyDateFinal}" '+%s'`

    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "wordpress_api_stats,site=$WPSiteURL dailyviews=$WPAPIStatsDailyViews,dailyvisitors=$WPAPIStatsDailyVisitors $WPAPIStatsDailyTimeStamp"
    arraydaily=$arraydaily+1
done

##
# Wordpress.com Jetpack Monthly Stats - Default Query to obtain last x months (by default 30)
##
WPAPIMonths="30"
WPAPIURL="https://public-api.wordpress.com/rest/v1.1/sites/$WPSiteURL/stats/visits?unit=month&quantity=$WPAPIMonths&http_envelope=1&"
WPAPIMonthlyStatsURL=$(curl -X GET --header "Accept:application/json" --header 'Authorization:Bearer '$WPAuthBearer'' "$WPAPIURL" 2>&1 -k --silent)

declare -i arraymonthly=0
for row in $(echo "$WPAPIMonthlyStatsURL" | jq -r '.body.data[][1]'); do
    WPAPIStatsMonthlyViews=$(echo "$WPAPIMonthlyStatsURL" | jq --raw-output ".body.data[$arraymonthly][1]")  
    WPAPIStatsMonthlyVisitors=$(echo "$WPAPIMonthlyStatsURL" | jq --raw-output ".body.data[$arraymonthly][2]")
    WPAPIStatsMonthlyDate=$(echo "$WPAPIMonthlyStatsURL" | jq --raw-output ".body.data[$arraymonthly][0]")
    WPAPIStatsMonthlyDateTime="T00:00:00Z"
    WPAPIStatsMonthlyDateFinal=$(echo $WPAPIStatsMonthlyDate$WPAPIStatsMonthlyDateTime)
    WPAPIStatsMonthlyTimeStamp=`date -d "${WPAPIStatsMonthlyDateFinal}" '+%s'`

    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "wordpress_api_stats,site=$WPSiteURL monthlyviews=$WPAPIStatsMonthlyViews,monthlyvisitors=$WPAPIStatsMonthlyVisitors $WPAPIStatsMonthlyTimeStamp"
    arraymonthly=$arraymonthly+1
done

##
# Wordpress.com Jetpack Yearly Stats - Default Query to obtain last x years (by default 10)
##
WPAPIYears="10"
WPAPIURL="https://public-api.wordpress.com/rest/v1.1/sites/$WPSiteURL/stats/visits?unit=year&quantity=$WPAPIYears&http_envelope=1&"
WPAPIYearlyStatsURL=$(curl -X GET --header "Accept:application/json" --header 'Authorization:Bearer '$WPAuthBearer'' "$WPAPIURL" 2>&1 -k --silent)

declare -i arrayyearly=0
for row in $(echo "$WPAPIYearlyStatsURL" | jq -r '.body.data[][1]'); do
    WPAPIStatsYearlyViews=$(echo "$WPAPIYearlyStatsURL" | jq --raw-output ".body.data[$arrayyearly][1]")  
    WPAPIStatsYearlyVisitors=$(echo "$WPAPIYearlyStatsURL" | jq --raw-output ".body.data[$arrayyearly][2]")
    WPAPIStatsYearlyDate=$(echo "$WPAPIYearlyStatsURL" | jq --raw-output ".body.data[$arrayyearly][0]")
    WPAPIStatsYearlyDateTime="T00:00:00Z"
    WPAPIStatsYearlyDateFinal=$(echo $WPAPIStatsYearlyDate$WPAPIStatsYearlyDateTime)
    WPAPIStatsYearlyTimeStamp=`date -d "${WPAPIStatsYearlyDateFinal}" '+%s'`

    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "wordpress_api_stats,site=$WPSiteURL yearlyviews=$WPAPIStatsYearlyViews,yearlyyvisitors=$WPAPIStatsYearlyVisitors $WPAPIStatsYearlyTimeStamp"
    arrayyearly=$arrayyearly+1
done

##
# Wordpress.com Jetpack Current Year Per Country Stats - Default Query to obtain current year visits per Country
##
WPAPIURL="https://public-api.wordpress.com/rest/v1.1/sites/$WPSiteURL/stats/country-views?period=year&http_envelope=1&"
WPAPIYearlyCountry=$(curl -X GET --header "Accept:application/json" --header 'Authorization:Bearer '$WPAuthBearer'' "$WPAPIURL" 2>&1 -k --silent)

WPAPICurrentYear=$(date +%Y)
WPAPICurrentYearDate="-01-01"
WPAPICurrentYearFinal=$(echo \"$WPAPICurrentYear$WPAPICurrentYearDate\")

declare -i arrayyearcountry=0
for row in $(echo "$WPAPIYearlyCountry" | jq -r ".body.days.$WPAPICurrentYearFinal.views[].views"); do
    WPAPIStatsYearCountryViews=$(echo "$WPAPIYearlyCountry" | jq --raw-output ".body.days.$WPAPICurrentYearFinal.views[$arrayyearcountry].views")  
    WPAPIStatsYearCountry=$(echo "$WPAPIYearlyCountry" | jq --raw-output ".body.days.$WPAPICurrentYearFinal.views[$arrayyearcountry].country_code")
    WPAPIStatsYearDate=$(echo "$WPAPIYearlyStatsURL" | jq --raw-output ".body.date")
    WPAPIStatsYearDateTime="T00:00:00Z"
    WPAPIStatsYearDateFinal=$(echo $WPAPIStatsYearDate$WPAPIStatsYearDateTime)
    WPAPIStatsYearTimeStamp=`date -d "${WPAPIStatsYearDateFinal}" '+%s'`

    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "wordpress_api_stats,site=$WPSiteURL,country=$WPAPIStatsYearCountry visits=$WPAPIStatsYearCountryViews $WPAPIStatsYearTimeStamp"
    arrayyearcountry=$arrayyearcountry+1
done
