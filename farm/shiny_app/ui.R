library(rhandsontable)
library(shiny)
editTable <- function(db_pw, outdir=getwd(), outfilename="table"){
  
    con = dbConnect(RMySQL::MySQL(), host = "localhost",
                    user = "root", password = db_pw)
    
    nn = dbSendQuery(con, "select * from farm_db.field_year_transaction")
    DFX = dbFetch(nn)
    
  
  
  DF = data.frame(DFX)
  
  insert_data = function(xx,db_pw){
    xx[is.na(xx)] = 0
    xx = xx[,c("field_key","year_key" ,"trans_type" ,"object_type","invoice_date","paid_date","vendor","expense_category","paid_amount","received_amount")]
    send_q = paste0("insert into farm_db.staging_field_year_transaction (field_key ,
        year_key ,
        trans_type ,
        object_type,
        invoice_date,
        paid_date,
        vendor,
        expense_category,
        paid_amount,
        received_amount ) values ", paste0(apply(xx, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", "))
  con = dbConnect(RMySQL::MySQL(), host = "localhost",
                  user = "root", password = db_pw)
  
  dbSendQuery(con, send_q)}
  
  
  ui = shinyUI(fluidPage(
    
    titlePanel("Edit and save a table"),
    sidebarLayout(
      sidebarPanel(
        helpText("Shiny app based on an example given in the rhandsontable package.", 
                 "Right-click on the table to delete/insert rows.", 
                 "Double-click on a cell to edit"),
        
        wellPanel(
          h3("Table options"),
          radioButtons("useType", "Use Data Types", c("TRUE", "FALSE"))
        ),
        br(), 
        
        wellPanel(
          h3("Save table"), 
          div(class='row', 
              div(class="col-sm-6", 
                  actionButton("save", "Save")),
              div(class="col-sm-6",
                  radioButtons("fileType", "File type", c("ASCII", "RDS")))
          )
        )
        
      ),
      
      mainPanel(
        wellPanel(
          uiOutput("message", inline=TRUE)
        ),
        
        actionButton("cancel", "Cancel last action"),
        br(), br(), 
        
        rHandsontableOutput("hot"),
        br(),
        
        wellPanel(
          h3("Add a column"),
          div(class='row', 
              div(class="col-sm-5", 
                  uiOutput("ui_newcolname"),
                  actionButton("addcolumn", "Add")),
              div(class="col-sm-4", 
                  radioButtons("newcolumntype", "Type", c("integer", "double", "character"))),
              div(class="col-sm-3")
          )
        )
        
      )
    )
  ))
  
  server <- shinyServer(function(input, output) {
    
    values <- reactiveValues()
    
    ## Handsontable
    observe({
      if (!is.null(input$hot)) {
        values[["previous"]] <- isolate(values[["DF"]])
        DF = hot_to_r(input$hot)
      } else {
        if (is.null(values[["DF"]]))
          DF <- DF
        else
          DF <- values[["DF"]]
      }
      values[["DF"]] <- DF
    })
    
    output$hot <- renderRHandsontable({
      DF <- values[["DF"]]
      if (!is.null(DF))
        rhandsontable(DF, useTypes = as.logical(input$useType), stretchH = "all")
    })
    
    ## Save 
    observeEvent(input$save, {
      fileType = isolate(input$fileType)
      finalDF = isolate(values[["DF"]])
      new_values = setdiff(finalDF$id,DFX$id)
      values_to_delete = setdiff(DFX$id, finalDF$id)
      print(new_values)
      print(values_to_delete)
      
      
      if(fileType == "ASCII"){
        dput(finalDF, file=file.path(outdir, sprintf("%s.txt", outfilename)))
      }
      else{
        saveRDS(finalDF, file=file.path(outdir, sprintf("%s.rds", outfilename)))
      }
    }
    )
    
    ## Cancel last action    
    observeEvent(input$cancel, {
      if(!is.null(isolate(values[["previous"]]))) values[["DF"]] <- isolate(values[["previous"]])
    })
    
    ## Add column
    output$ui_newcolname <- renderUI({
      textInput("newcolumnname", "Name", sprintf("newcol%s", 1+ncol(values[["DF"]])))
    })
    observeEvent(input$addcolumn, {
      DF <- isolate(values[["DF"]])
      values[["previous"]] <- DF
      newcolumn <- eval(parse(text=sprintf('%s(nrow(DF))', isolate(input$newcolumntype))))
      values[["DF"]] <- setNames(cbind(DF, newcolumn, stringsAsFactors=FALSE), c(names(DF), isolate(input$newcolumnname)))
    })
    
    ## Message
    output$message <- renderUI({
      if(input$save==0){
        helpText(sprintf("This table will be saved in folder \"%s\" once you press the Save button.", outdir))
      }else{
        outfile <- ifelse(isolate(input$fileType)=="ASCII", "table.txt", "table.rds")
        fun <- ifelse(isolate(input$fileType)=="ASCII", "dget", "readRDS")
        list(helpText(sprintf("File saved: \"%s\".", file.path(outdir, outfile))),
             helpText(sprintf("Type %s(\"%s\") to get it.", fun, outfile)))
      }
    })
    
  })
  
  ## run app 
  runApp(list(ui=ui, server=server))
  return(invisible())
}