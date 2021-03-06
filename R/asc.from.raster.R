#' Raster conversion functions for adehabitat, raster and sp packages
#' 
#' \code{asc.from.raster} and \code{asc.from.sp} extracts data from objects of
#' class 'RasterLayer' (raster package) and class 'SpatialGridDataFrame' (sp
#' package) into an object of class 'asc' (SDMTools & adehabitat packages). \cr
#' \cr \code{raster.from.asc} and \code{sp.from.asc} does the reverse.\cr\cr
#' \code{as.asc} creates an object of class 'asc' (SDMTools & adehabitat
#' packages) from a matrix of data. Code & helpfile associated with
#' \code{as.asc} were modified from adehabitat package.
#' 
#' These functions provide capabilities of using scripts / functions from many
#' packages including adehabitat (plus e.g, SDMTools), sp (plus e.g., maptools,
#' rgdal) and raster.
#' 
#' @param x is an object of class 'asc', 'RasterLayer' or
#' 'SpatialGridDataFrame'. For the function \code{as.asc}, a matrix
#' @param projs is a CRS projection string of the Proj4 package
#' @param xll the x coordinate of the center of the lower left pixel of the map
#' @param yll the y coordinate of the center of the lower left pixel of the map
#' @param cellsize the size of a pixel on the studied map
#' @param type a character string. Either \code{"numeric"} or \code{"factor"}
#' @param lev if \code{type = "factor"}, either a vector giving the labels of
#' the factor levels, or the name of a file giving the correspondence table of
#' the map (see adehabitat as.asc helpfile details)
#' @return Returns an object of class requested.
#' @author Jeremy VanDerWal \email{jjvanderwal@@gmail.com}
#' @examples
#' 
#' 
#' #create a simple object of class 'asc'
#' tasc = as.asc(matrix(rep(x=1:10, times=1000),nr=100)); print(tasc)
#' str(tasc)
#' 
#' #convert to RasterLayer
#' traster = raster.from.asc(tasc)
#' str(traster)
#' 
#' #convert to SpatialGridDataFrame
#' tgrid = sp.from.asc(tasc)
#' str(tgrid)
#' 
#' #create a basic object of class asc
#' tasc = as.asc(matrix(rep(x=1:10, times=1000),nr=100)); print(tasc)
#' 
#' 
#' @export 
asc.from.raster = function(x) {
	if (!any(class(x) %in% 'RasterLayer')) stop('x must be of class raster or RasterLayer')
	cellsize = (x@extent@ymax-x@extent@ymin)/x@nrows
	yll = x@extent@ymin + 0.5 * cellsize
	xll = x@extent@xmin + 0.5 * cellsize
	tmat = t(matrix(getValues(x),nrow=x@nrows,ncol=x@ncols,byrow=T)[x@nrows:1,])
	tmat[which(tmat==x@file@nodatavalue)] = NA
	return(as.asc(tmat,yll=yll,xll=xll,cellsize=cellsize))
}

#' @rdname asc.from.raster
#' @export
raster.from.asc = function(x,projs=NA) {
	if (class(x) != 'asc') stop('x must be of class asc')
	require(raster)
	cellsize = attr(x, "cellsize")
	nrows = dim(x)[2]; ncols= dim(x)[1]
	xmin = attr(x, "xll") - 0.5 * cellsize
	ymin = attr(x, "yll") - 0.5 * cellsize
	xmax = xmin + ncols*cellsize
	ymax = ymin + nrows*cellsize
	r <- raster(ncols=ncols, nrows=nrows, xmn=xmin, xmx=xmax, ymn=ymin, ymx=ymax)
	projection(r) <- projs
	tvals = as.vector(t(t(unclass(x))[nrows:1,])); tvals[which(is.na(tvals))] = r@file@nodatavalue
	r <- setValues(r, as.vector(t(t(unclass(x))[nrows:1,])))
	return(r)
}

#' @rdname asc.from.raster
#' @export
asc.from.sp = function(x) {
	#assumes single band data
	if (!any(class(x) == 'SpatialGridDataFrame')) stop('x must be of class SpatialGridDataFrame')
	cellsize = mean(x@grid@cellsize)
	yll = as.numeric(x@grid@cellcentre.offset[2])
	xll = as.numeric(x@grid@cellcentre.offset[1])
	names(x@data)[1] = 'z'
	tmat = t(matrix(x@data$z,nrow=x@grid@cells.dim[2],ncol=x@grid@cells.dim[1],byrow=T)[x@grid@cells.dim[2]:1,])
	return(as.asc(tmat,yll=yll,xll=xll,cellsize=cellsize))
}

#' @rdname asc.from.raster
#' @export
sp.from.asc = function(x,projs=CRS(as.character(NA))) {
	if (!inherits(x, "asc")) stop('x must be of class asc')
	require(sp)
	tgrid = GridTopology(c(attr(x, "xll"),attr(x, "yll")),rep(attr(x, "cellsize"),2),dim(x))
	return(SpatialGridDataFrame(tgrid,data.frame(z=as.vector(unclass(x)[,dim(x)[2]:1])),proj4string=projs))
}

#' @rdname asc.from.raster
#' @export
as.asc = function(x, xll=1, yll=1, cellsize=1,type=c("numeric", "factor"),lev=levels(factor(x))) {
    #check inputs
    type=match.arg(type)
    if (!inherits(x, "matrix")) stop("x should be a matrix")
    # creates the attributes
    mode(x) = "numeric"; attr(x, "xll") = xll; attr(x, "yll") = yll
    attr(x, "cellsize")=cellsize; attr(x, "type") = type
    if (type=="factor") attr(x, "levels") = lev
    class(x) = "asc"
    #return the object
    return(x)
}
