library(RMySQL)
library(ggplot2)
library(gmailr)
library(reshape)
report_cost = function(db_pw){
  con = dbConnect(RMySQL::MySQL(), host = "localhost",
                  user = "root", password = db_pw)
  
  nn = dbGetQuery(con, "select * from farm_db.yearly_financials")
  #dbClearResult(nn)
  dbDisconnect(con)
  
  
  out_plot = ggplot(subset(nn,trans_type =='debit'),aes(fill = object_type,x = factor(year_key), y = paid_amount, label = paid_amount))+
    geom_bar(
      position="stack", stat="identity")+
    facet_wrap(~field_key)+
    geom_text(aes(label = dollar(paid_amount)),size = 3, position = position_stack(vjust = 0.5))+
    scale_y_continuous("Amount Paid")+
    ggtitle("Yearly Cost Breakdown")+
    scale_x_discrete("Crop Year") + 
    theme_economist()
  return(out_plot)}


annual_financials = function(db_pw, switcher){
  con = dbConnect(RMySQL::MySQL(), host = "localhost",
                  user = "root", password = db_pw)
  
  nn = dbGetQuery(con, "select * from farm_db.yearly_agg_financials order by year_key")
  dbDisconnect(con)
  print(head(nn))
  nn[is.na(nn)] = 0
  nn$ebitda = nn$revenue-nn$costs
  nn$profit = (nn$revenue
    - nn$costs
    - nn$interest_payment)

  nn$cash_flow = (nn$revenue 
    - nn$costs 
    - nn$interest_payment
    - nn$principal_payment
    - nn$capital_payment)

  nn$cum_cash_flow = cumsum(nn$cash_flow)
  print(nn)
  
  
  nn = nn[,c("field_key", "year_key","costs","revenue","ebitda","profit","cash_flow","cum_cash_flow")]
  print(nn)
  molten = reshape::melt(nn, id = c("field_key","year_key"))
  print(molten)
  molten1 = subset(molten, variable %in% c("costs","revenue","ebitda","profit"))
  if(switcher == 1){out_plot = (ggplot(molten1,
                     aes(fill = variable,x = factor(year_key), y = value, label = value))+
                geom_bar(position="dodge", stat="identity")+
                facet_wrap(~field_key)+
                geom_text(aes(label = dollar(value)),size = 3, position = position_dodge(.9))+
                scale_y_continuous("Finance Metric")+
                scale_x_discrete("Crop Year")+ 
                ggtitle("Yearly Financials by Field")+
                theme_economist())} else {
        
    out_plot = (ggplot(subset(molten,variable == "cum_cash_flow"),
               aes(x = factor(year_key), y = value, label = value))+
          geom_bar( stat="identity")+
          facet_wrap(~field_key)+
          geom_text(aes(label = dollar(value)),size = 3)+
          scale_y_continuous("Finance Metric")+
          scale_x_discrete("Crop Year")+ 
            ggtitle("Cumulative Cash Flow by Field")+
            theme_economist())}
  
  return(out_plot)
  }

annual_financials_agg = function(db_pw, switcher){
  con = dbConnect(RMySQL::MySQL(), host = "localhost",
                  user = "root", password = db_pw)
  
  nn = dbGetQuery(con, "select * from farm_db.yearly_agg_agg_financials order by year_key")
  dbDisconnect(con)
  #dbClearResult(nn)
  print(head(nn))
  nn[is.na(nn)] = 0
  nn$ebitda = nn$revenue-nn$costs
  nn$profit = (nn$revenue
               - nn$costs
               - nn$interest_payment)
  
  nn$cash_flow = (nn$revenue 
                  - nn$costs 
                  - nn$interest_payment
                  - nn$principal_payment
                  - nn$capital_payment)
  
  nn$cum_cash_flow = cumsum(nn$cash_flow)
  print(nn)
  
  
  nn = nn[,c("year_key","costs","revenue","ebitda","profit","cash_flow","cum_cash_flow")]
  print(nn)
  molten = reshape::melt(nn, id = c("year_key"))
  print(molten)
  molten1 = subset(molten, variable %in% c("costs","revenue","ebitda","profit"))
  if(switcher == 1){out_plot = (ggplot(molten1,
               aes(fill = variable,x = factor(year_key), y = value, label = value))+
          geom_bar(position="dodge", stat="identity")+
          geom_text(aes(label = dollar(value)),size = 3, position = position_dodge(.9))+
          scale_y_continuous("Finance Metric")+
          scale_x_discrete("Crop Year")+ 
            ggtitle("Yearly Financials")+
            theme_economist())} else {
  
  out_plot = (ggplot(subset(molten,variable == "cum_cash_flow"),
               aes(x = factor(year_key), y = value, label = value))+
          geom_bar( stat="identity")+
          geom_text(aes(label = dollar(value)),size = 3)+
          scale_y_continuous("Finance Metric")+
          scale_x_discrete("Crop Year")+ 
            ggtitle("Cumulative Cash Flow")+
            theme_economist())}
  
  return(out_plot)
}




