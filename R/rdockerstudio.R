examples.RDockerStudioApp = function() {
  app  = RDockerStudioApp()
  viewApp(app,launch.browser = rstudioapi::viewer)
}

#' View RDockerStudio in the RStudio pane
#'
#' Makes sense when being logged-in to an RStudio server instance
#' that is running on a webserver that has docker containers.
#' Your user must be able to run docker commands
#' @export
viewRDockerStudio = function() {
  library(RDockerStudio)
  app =RDockerStudioApp()
  viewApp(app,launch.browser = rstudioapi::viewer)
}

#' Create an RDockerStudio shinyEvents app
#' @export
RDockerStudioApp  = function() {
  app = eventsApp()

  app$ui = fluidPage(
    tabsetPanel(
      tabPanel(title="Containers",
        br(),
        uiOutput("contTableUI"),
        actionButton("contRefreshBtn","Refresh"),
        actionButton("contPauseBtn","Pause"),
        actionButton("contUnpauseBtn","Unpause"),
        actionButton("contStartBtn","Start"),
        actionButton("contStopBtn","Stop"),
        actionButton("contRemoveBtn","Remove"),
        uiOutput("contMsgUI")
      ),
      tabPanel(title="Images",
        br(),
        uiOutput("imgTableUI"),
        actionButton("imgRefreshBtn","Refresh"),
        actionButton("imgRemoveBtn","Remove"),
        uiOutput("imgMsgUI")
      ),
      tabPanel(title="Ressources",
        br(),
        uiOutput("resUI")
      )
    )
  )

  appInitHandler(function(app,...) {
    restore.point("appInit")
    refresh.container.table(app=app)
    refresh.image.table(app=app)
    if (!is.null(app$res.obs)) app$res.obs$destroy()
    app$res.obs=observe({
      refresh.res(app=app)
      invalidateLater(3000)
    })
  })


  container.command = function(fun,app=getApp(),...) {
    restore.point("containerCommand")
    if (is.null(app$cont.row)) {
      show.cont.msg("Please select a container by clicking on its row.")
      return()
    }
    dr = app$cont.df[app$cont.row,,drop=FALSE]
    show.cont.msg("Please wait ...")
    msg = fun(dr$names)
    show.cont.msg(msg)
    refresh.container.table(app)
  }


  buttonHandler("contPauseBtn", function(app=getApp(),...) {
    container.command(pause.docker.container)
  })
  buttonHandler("contUnpauseBtn", function(app=getApp(),...) {
    container.command(unpause.docker.container)
  })

  buttonHandler("contStartBtn", function(app=getApp(),...) {
    container.command(start.docker.container)
  })
  buttonHandler("contStopBtn", function(app=getApp(),...) {
    container.command(stop.docker.container)
  })
  buttonHandler("contRemoveBtn", function(app=getApp(),...) {
    container.command(remove.docker.container)
  })

  buttonHandler("contRefreshBtn", function(app=getApp(),...) {
    show.cont.msg("Refresh container table")
    refresh.container.table(app)
  })

  buttonHandler("imgRefreshBtn", function(app=getApp(),...) {
    show.cont.msg("Refresh image table")
    refresh.image.table(app)
  })

  buttonHandler("imgRemoveBtn", function(app=getApp(),...) {
    restore.point("imgRemoveBtn")
    if (is.null(app$img.row)) {
      show.cont.msg("Please select an image by clicking on its row.")
      return()
    }
    dr = app$img.df[app$img.row,,drop=FALSE]
    show.img.msg("Please wait ...")
    msg = remove.docker.image(dr$id)
    show.img.msg(msg)
    refresh.image.table(app)
  })


  app
}

refresh.container.table = function(app=getApp()) {
  restore.point("refresh.container.table")
  df = get.docker.containers()
  app$cont.df = df
  app$cont.row = NULL

  bg = c("#dddddd","#ffffff")[df$active+1]
  html = html.table(df,id = "contTable", bg.color=bg)
  setUI("contTableUI",HTML(html))

  tdClickHandler(id="contTable", eventId="contTable", auto.select = TRUE, function(app=getApp(),...) {
    args = list(...)
    restore.point("container.tdClickerHandler")
    app$cont.row = args$data$row
    cat("\nSet app$cont.row = ", app$cont.row)
  })

}

start.docker.container = function(name) {
  restore.point("start.docker.container")
  cmd = paste0('docker start ',name)
  txt = try(system(cmd, intern=TRUE))
  if (is(txt,"try-error")) {
    txt = as.character(txt)
  } else {
    txt = paste0("started ", txt)
  }
  txt
}

stop.docker.container = function(name) {
  restore.point("start.docker.container")
  cmd = paste0('docker stop ',name)
  txt = try(system(cmd, intern=TRUE))
  if (is(txt,"try-error")) {
    txt = as.character(txt)
  } else {
    txt = paste0("stopped ", txt)
  }
  txt
}


remove.docker.container = function(name) {
  restore.point("remove.docker.container")
  txt = system2("docker",args = paste0("rm ",name),stderr = TRUE,stdout = TRUE)
  #txt = capture.output(system2(cmd), type="message")
  paste0(txt,collapse="\n")
}


show.cont.msg= function(str) {
  dsetUI("contMsgUI",HTML(str))
  setUI("contMsgUI",HTML(str))
}


refresh.image.table = function(app=getApp()) {
  restore.point("refresh.image.table")
  df = get.docker.images()
  app$img.df = df
  app$img.row = NULL
  html = html.table(df,id = "imgTable")
  setUI("imgTableUI",HTML(html))

  tdClickHandler(id="imgTable", eventId="imgTable", auto.select = TRUE, function(app=getApp(),...) {
    args = list(...)
    restore.point("image.tdClickerHandler")
    app$img.row = args$data$row
    cat("\nSet app$img.row = ", app$img.row)
  })


}



show.img.msg= function(str) {
  dsetUI("imgMsgUI",HTML(str))
  setUI("imgMsgUI",HTML(str))
}



remove.docker.image = function(id) {
  restore.point("remove.docker.image")
  txt = system2("docker",args = paste0("rmi ",id),stderr = TRUE,stdout = TRUE)
  #txt = capture.output(system2(cmd), type="message")
  paste0(txt,collapse="\n")
}



get.docker.containers = function() {
  restore.point("get.docker.containers")

  # .ID 	Container ID
  # .Image 	Image ID
  # .Command 	Quoted command
  # .CreatedAt 	Time when the container was created.
  # .RunningFor 	Elapsed time since the container was started.
  # .Ports 	Exposed ports.
  # .Status 	Container status.
  # .Size 	Container disk size.
  # .Names 	Container names.
  # .Labels 	All labels assigned to the container.
  # .Label 	Value of a specific label for this container. For example '{{.Label "com.docker.swarm.cpu"}}'
  # .Mounts 	Names of the volumes mounted in this container.


  txt = system('docker ps -a --format \'"{{.ID}}";"{{.Names}}";"{{.Image}}";"{{.RunningFor}}";"{{.Status}}";"{{.Ports}}";"{{.Size}}";"{{.CreatedAt}}";"{{.Labels}}";"{{.Mounts}}"\'', intern=TRUE)

  txt

  df = read.table(textConnection(txt),sep = ";",col.names = c("id","names","image","runningFor","status","ports","size","created","labels","mounts"), stringsAsFactors = FALSE)
  df$active = substring(df$status,1,2)=="Up"
  df = df[order(-df$active),,drop=FALSE]
  df
}

get.docker.images = function() {
  restore.point("get.docker.images")
  txt = system('docker images --format "{{.ID}};{{.Repository}};{{.Tag}};{{.Size}};{{.CreatedAt}}"',intern = TRUE)
  txt
  idf = read.table(textConnection(txt),sep = ";",col.names = c("id","repository","tag","size","created"), stringsAsFactors = FALSE)
  idf
}

refresh.res = function(app=app) {
  restore.point("refresh.res")
  #txt = docker.stats()
  #html = paste0("<pre>", paste0(txt, collapse="\n"),"</pre>")
  dat = docker.stats()
  html = html.table(dat)
  dsetUI("resUI", HTML(html))
  setUI("resUI", HTML(html))

}

docker.stats = function() {
  library(stringtools)

  txt = system("docker stats --no-stream", intern=TRUE)
  txt
  w = c(20,20,23,20,22,20,4)
  dat = read.fwf(textConnection(txt[-1]),widths = w,stringsAsFactors=FALSE)
  dat = as.data.frame(lapply(dat, str.trim))
  colnames(dat) = c("CONTAINER","CPU %","MEM USAGE / LIMIT","MEM %","NET I/O","BLOCK I/O","PIDS")
  dat
}
