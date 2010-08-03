    <%--
        Document   : show
        Created on : Apr 21, 2010, 9:36:39 AM
        Author     : "Nick dos Remedios <Nick.dosRemedios@csiro.au>"
    --%>
    <%@ page contentType="text/html" pageEncoding="UTF-8" %>
    <%@ include file="/common/taglibs.jsp" %>
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
            <title>Explore Your Area</title>
            <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;sensorfalse&amp;key=${googleKey}" type="text/javascript"></script>
            <script type="text/javascript" src="${pageContext.request.contextPath}/static/js/openlayers/OpenLayers.js"></script>
            <script type="text/javascript">
                // Global variables for Openlayers
                var lon = ${longitude};
                var lat = ${latitude};
                //make the taxa and rank global variable so that they can be used in the download
                var taxa =[]
                taxa[0] ="*";
                var rank ="*";
                var zoom = ${zoom};
                var map, vectorLayer, selectControl, selectFeature, markerLayer, circleLayer;
                var geocoder;
                var proj900913 = new OpenLayers.Projection("EPSG:900913");
                var proj4326 = new OpenLayers.Projection("EPSG:4326");

                /**
                 * Openlayers map
                 */
                function loadMap() {
                    // create OpenLayers map object
                    map = new OpenLayers.Map('yourMap',{maxResolution: 2468,controls: []});
                    //add controls - restrict mouse wheel chaos
                    map.addControl(new OpenLayers.Control.Navigation({zoomWheelEnabled:false}));
                    map.addControl(new OpenLayers.Control.ZoomPanel());
                    map.addControl(new OpenLayers.Control.PanPanel());
                    map.addControl(new OpenLayers.Control.LayerSwitcher({ascending: false}));
                    //map.addControl(new OpenLayers.Control.OverviewMap());
                    // create Google base layers
                    var gmap = new OpenLayers.Layer.Google(
                        "Google Streets",
                        {'sphericalMercator': true,
                        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34)}
                    );
                    //map.addLayer(gmap);
                    var gsat = new OpenLayers.Layer.Google(
                        "Google Satellite",
                        {type: G_SATELLITE_MAP, 'sphericalMercator': true, numZoomLevels: 22}
                    );
                    //map.addLayer(gsat);
                    var ghyb = new OpenLayers.Layer.Google(
                        "Google Hybrid",
                        {'sphericalMercator': true, maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34), type: G_HYBRID_MAP}
                    );
                    //map.addLayer(ghyb);
                    map.addLayers([ghyb, gsat, gmap ]);

                    var point = new OpenLayers.LonLat(lon, lat);
                    map.setCenter(point.transform(proj4326, map.getProjectionObject()), zoom);
                    // reload vector layer on zoom event
                    map.events.register('zoomend', map, function (e) {
                        drawCircleRadius();
                        loadRecordsLayer();
                        loadSelectControl();
                    });

                    // marker pin (Google-style)
                    markerLayer = new OpenLayers.Layer.Vector("Pin");
                    var pinPoint = new OpenLayers.Geometry.Point(lon, lat);
                    var feature = new OpenLayers.Feature.Vector(
                        pinPoint.transform(proj4326, map.getProjectionObject()),
                        {title:'Your location' },
                        {externalGraphic: '${pageContext.request.contextPath}/static/css/images/marker.png', graphicHeight: 28, graphicWidth: 18, graphicYOffset: -24 , graphicZIndex: 1000, rendererOptions: {zIndexing: true}}
                    );

                    markerLayer.addFeatures(feature);
                    map.addLayer(markerLayer);
                    markerLayer.setZIndex(1000);

                    // load circle showing area included in search
                    drawCircleRadius();
                    // load occurrences data onto map
                    loadRecordsLayer();
                    // register select events on occurrence opints
                    //loadSelectControl();
                }

                /**
                 * Load the occurrence records & display as points on map
                 */
                function loadRecordsLayer(taxa, rank) {
                    // remove existing data if present
                    if (vectorLayer != null) {
                        vectorLayer.destroy();
                        vectorLayer = null;
                    }

                    // configuring the styling of the vetor layer
                    var myStyles = new OpenLayers.StyleMap({
                        "default": new OpenLayers.Style({
                            pointRadius: 4,
                            fillColor: "${'${color}'}",
                            strokeColor: "${'${color}'}",
                            fillOpacity: 0.7,
                            graphicZIndex: "${'${count}'}",
                            strokeWidth: 0
                        })
                    });

                    // URL for GeoJSON web service
                    var geoJsonUrl = "${pageContext.request.contextPath}/geojson/radius-points"; //+"&zoom=4&callback=?";
                    // request params for ajax geojson call
                    var params = {
                        "taxa": taxa,
                        "rank": rank,
                        "lat": ${latitude},
                        "long":  ${longitude},
                        "radius": ${radius}
                    };
                    // projection options
                    var proj_options = {
                        'internalProjection': map.baseLayer.projection,
                        'externalProjection': proj4326
                    };
                    
                    // create vector layer for occurrence points
                    vectorLayer = new OpenLayers.Layer.Vector("Occurrences", {
                        projection: map.baseLayer.projection,
                        styleMap: myStyles,
                        rendererOptions: {zIndexing: true},
                        //attribution: legend,
                        strategies: [new OpenLayers.Strategy.Fixed()], // new OpenLayers.Strategy.Fixed(),new OpenLayers.Strategy.BBOX()
                        protocol: new OpenLayers.Protocol.HTTP({
                            url: geoJsonUrl,
                            params: params,
                            format: new OpenLayers.Format.GeoJSON(proj_options)
                        })
                    });

                    map.addLayer(vectorLayer);
                    vectorLayer.refresh();
                    markerLayer.setZIndex(1000); // so pin icon isn't covered with points
                }
                
                /**
                 * Draw a circle representing the area included in occurrence records search
                 */
                function drawCircleRadius() {
                    if (circleLayer != null) {
                        circleLayer.destroy();
                        circleLayer = null;
                    }

                    circleLayer = new OpenLayers.Layer.Vector("Cirlce", {projection: map.getProjectionObject()});
                    var point = new OpenLayers.Geometry.Point(lon, lat);
                    //alert('proj = '+map.getProjectionObject());
                    var DOTS_PER_UNIT = OpenLayers.INCHES_PER_UNIT.km * OpenLayers.DOTS_PER_INCH;
                    
                    var rad = ${radius} * DOTS_PER_UNIT / map.getScale(); 
                    // add fudge factor for spherical mercapter projection (Google maps)
                    // function was determined using http://www.xuru.org/rt/NLR.asp
                    // works well for middle latitidues but is abit out for Hobart and Darwin
                    if (map.getProjectionObject() == "EPSG:900913") {
                        // (Math.pow(1.005940831, Math.abs(lat))
                        // (0.3534329364 * Math.log(Math.abs(lat))
                        // (Math.pow(Math.abs(lat), 0.55373737645) 
                        rad = rad * (Math.pow(1.005940831, Math.abs(lat)));
                    }
                    var style_green = {
                        fillColor: "lightBlue",
                        fillOpacity: 0.1,
                        strokeColor: "lightBlue",
                        strokeOpacity: 0.8,
                        strokeWidth: 1,
                        //graphicZIndex: 10,
                        pointRadius: rad
                        //pointerEvents: "visiblePainted"
                    };
                    var pointFeature = new OpenLayers.Feature.Vector(point.transform(proj4326, map.getProjectionObject()),{},style_green);
                    //pointFeature.transform(proj4326, map.getProjectionObject());
                    circleLayer.addFeatures([pointFeature]);
                    map.addLayer(circleLayer);
                    //circleLayer.setZIndex(10);
                }
                
                /**
                 * Geocode location via Google Maps API
                 */
                function addAddressToPage(response) {
                    //map.clearOverlays();
                    if (!response || response.Status.code != 200) {
                        alert("Sorry, we were unable to geocode that address");
                    } else {
                        var location = response.Placemark[0];
                        var lat = location.Point.coordinates[1]
                        var lon = location.Point.coordinates[0];
                        var locationStr = response.Placemark[0].address;
                        $('input#location').val(locationStr);
                        $('input#latitude').val(lat);
                        $('input#longitude').val(lon);
                        $('form#searchForm').submit();
                    }
                }

                /**
                 * Reverse geocode coordinates via Google Maps API
                 */
                function codeAddress(reverseGeocode) {
                    var address = $('input#address').val();
                    var lat = $('input#longitude').val();
                    var lon = $('input#latitude').val();

                    if (geocoder) {
                        if (reverseGeocode && lat && lon) {
                            var latLon = new GLatLng(lon,lat);
                            geocoder.getLocations(latLon, addAddressToPage);
                        }
                        else if (address) {
                            geocoder.getLocations(address, addAddressToPage);
                        }
                    }
                }
                
                function onFeatureSelect(feature) {
                    selectedFeature = feature;
                    popup = new OpenLayers.Popup.FramedCloud("chicken", feature.geometry.getBounds().getCenterLonLat(),
                    null, "<div style='font-size:.8em'>Records in area: " + feature.attributes.count, // +
                    //"<br /><a href=''>View records in this area</a> " + feature.geometry.getBounds() + "</div>",
                    null, true, onPopupClose);
                    feature.popup = popup;
                    map.addPopup(popup);
                }

                function onFeatureUnselect(feature) {
                    map.removePopup(feature.popup);
                    feature.popup.destroy();
                    feature.popup = null;
                }

                function onPopupClose(evt) {
                    selectControl.unselect(selectedFeature);
                }

                function destroyMap() {
                    if (map != null) {
                        //alert("destroying map");
                        map.destroy();
                        $("#pointsMap").html('');
                    }
                }

                /**
                 * Register select event on occurrence points
                 */
                function loadSelectControl() {
                    if (selectControl != null) {
                        map.removeControl(selectControl);
                        selectControl.destroy();
                        selectControl = null;
                    }

                    selectControl = new OpenLayers.Control.SelectFeature(vectorLayer, {
                        //hover: true,
                        onSelect: onFeatureSelect,
                        onUnselect: onFeatureUnselect
                    });

                    map.addControl(selectControl);
                    selectControl.activate();  // errors on map re-size/zoom change so commented-out for now
                }

                /**
                 * Process the JSON data from an AJAX request (species in area)
                 */
                function processSpeciesJsonData(data, appendResults) {
                    if (data.speciesCount > 0) {
                        // add an ordered list to the #taxaDiv div
                        if (!appendResults) {
                            $('#taxaDiv').html('<ol></ol>');
                        }
                        
                        var linkTitle = "display on map";
                        var infoTitle = "view species page";
                        var recsTitle = "view list of records";
                        // iterate over list of species from search
                        for (i=0;i<data.species.length;i++) {
                            // create a list item (li) 
                            var li = '<li><span><a id="taxon_name" class="taxonBrowse2" title="'+linkTitle+'" href="'+
                                    data.species[i].name+'"><i>'+data.species[i].name+'</i></a>';
                            // add common name
                            if (data.species[i].commonName) {
                                li = li + ' ('+data.species[i].commonName+')';
                            }
                            // add link to species page (if guid is set)
                            if (data.species[i].guid) {
                                li = li + ' <a title="'+infoTitle+'" href="${speciesPageUrl}'+data.species[i].guid+
                                    '"><img src="${pageContext.request.contextPath}/static/css/images/page_white_go.png" alt="species page icon" style="margin-bottom:-3px;"/></a>';
                            }
                            // add number of records
                            li = li + ' - '+data.species[i].count+' records <a href="${pageContext.request.contextPath}/occurrences/searchByArea?q=taxon_name:'+data.species[i].name+
                                '|'+$('input#latitude').val()+'|'+$('input#longitude').val()+'|'+$('select#radius').val()+'" class="" title="'+
                                recsTitle+'"><img src="${pageContext.request.contextPath}/static/css/images/database_go.png" '+
                                'alt="search list icon" style="margin-bottom:-3px;"/></a></span></li>';
                            // write list item to page
                            $('#taxa-level-1 #taxaDiv ol').append(li);
                        }

                        if (data.species.length == 50) {
                            // add load more link
                            var newStart = $('#taxaDiv ol li').length;
                            $('#taxa-level-1 #taxaDiv ol').after('<div id="loadMoreSpecies">&nbsp;<a href="'+newStart+'">Show more species</a></div>');
                        }
                        // Register onClick for "load more species" link
                        $('#loadMoreSpecies a').click(
                            function(e) {
                                e.preventDefault(); // ignore the href text - used for data
                                var start = $(this).attr('href');
                                //alert("start = "+start);
                                //console.log("start = "+start);
                                // AJAX...
                                var uri = "${pageContext.request.contextPath}/explore/species.json";
                                var params = "?latitude=${latitude}&longitude=${longitude}&radius=${radius}&taxa="+taxa+"&rank="+rank+"&start="+start;
                                //$('#taxaDiv').html('[loading...]');
                                $('#loadMoreSpecies').detach(); // delete it
                                $.getJSON(uri + params, function(data) {
                                    // process JSON data from request
                                    processSpeciesJsonData(data, true);
                                });
                            }
                        );
                    } else if (appendResults) {
                        $('#taxaDiv').after('');
                    } else {
                        $('#taxaDiv').html('[no species found]');
                    }

                    // highlight the active/current taxa/group
                    $('#taxa-level-1 tbody td').addClass("activeRow");
                    // Register clicks for the list of species links so that map changes
                    $('a.taxonBrowse2').click(function(e) {
                        e.preventDefault(); // ignore the href text - used for data
                        var taxon = $(this).attr('href');
                        rank = $(this).attr('id');
                        taxa = []; // array of taxa
                        taxa = (taxon.contains("|")) ? taxon.split("|") : taxon;
                        
                        $('#taxaDiv li').removeClass("activeRow2"); // un-highlight previous current taxon
                        $(this).parent().parent().addClass("activeRow2"); // highloght current taxon
                        loadRecordsLayer(taxa, rank);
                    });

                    // temp link for recrord search. TODO delete me when implemented
                    $('a.recordsLink').click(function(e) {
                        e.preventDefault();
                        alert("Not avaiable yet, sorry.");
                    });
                }

                /**
                 * Document onLoad event using JQuery
                 */
                $(document).ready(function() {
                    // re-call (skin) JS function to tweak with search input
                    greyInitialValues();
                    // instantiate GClientGeocoder
                    geocoder = new GClientGeocoder(); //new google.maps.Geocoder();
                    geocoder.setBaseCountryCode("AU");
                    // initial page load without params - geocode address
                    var location = $('input#location').val();
                    if (location == null || location == '') {
                        // geocode the provided address
                        codeAddress();
                    } else {
                        // load OpenLayers map
                        loadMap();
                    }

                    // onMouseOver event on Group items
                    $('a.taxonBrowse').parent().parent().hover(
                        function() {
                            $(this).addClass('hoverRow');
                        },
                        function() {
                            $(this).removeClass('hoverRow');
                        }
                    );
                    
                    // catch the link on the taxon groups table
                    $('.taxonBrowse').parent().parent().click(function(e) {
                        e.preventDefault(); // ignore the href text - used for data
                        var taxon = $(this).find('a.taxonBrowse').attr('href'); // $(this+' a.taxonBrowse').attr('href');
                        rank = $(this).find('a.taxonBrowse').attr('id');
                        taxa = []; // array of taxa
                        taxa = (taxon.contains("|")) ? taxon.split("|") : taxon;
                        //Internet Explorer for Windows versions up to and including 7 don’t support the value inherit.(http://reference.sitepoint.com/css/background-color)
                        $('#taxa-level-0 tr').removeClass("activeRow"); //css('background-color','white');
                        $(this).addClass("activeRow"); //css('background-color','#E8EACE');
                        $('#taxa-level-1 tbody tr').addClass("activeRow"); //.css('background-color','#E8EACE');
                        // load records layer on map
                        loadRecordsLayer(taxa, rank);
                        // AJAX...
                        var uri = "${pageContext.request.contextPath}/explore/species.json";
                        var params = "?latitude=${latitude}&longitude=${longitude}&radius=${radius}&taxa="+taxa+"&rank="+rank;
                        $('#taxaDiv').html('[loading...]');
                        $.getJSON(uri + params, function(data) {
                            // process JSON data from request
                            processSpeciesJsonData(data);
                        });
                    });

                    // By default action on page load - show the all species group (simulate a click)
                    $('#taxa-level-0 tbody td:first a.taxonBrowse').click();

                    // register click event on download button
                    $("button#download").click(
                        function(e){
                            e.preventDefault();
                            var downloadUrl ="${pageContext.request.contextPath}/explore/download?latitude=${latitude}&longitude=${longitude}&radius=${radius}&taxa="+taxa+"&rank=" + rank;
                            //alert("URL is " + downloadUrl);
                            if (confirm("Continue with download?\rClick 'OK' to download or 'cancel' to abort.")) {
                                window.location.replace(downloadUrl);
                            }

                        }
                    );

                    // register click event on "Search" button"
                    $('input#locationSearch').click(
                        function(e) {
                            e.preventDefault(); // ignore the href text - used for data
                            codeAddress();
                        }
                    );

                    // Register onChange event on radius drop-down - will re-submit form
                    $('select#radius').change(
                        function(e) {
                            $('form#searchForm').submit();
                        }
                    );

                    // Dynamically set height of #taxaDiv (to match containing div height)
                    var tbodyHeight = $('#taxa-level-0 tbody').height() + 2;
                    $('#taxaDiv').height(tbodyHeight);
                });
            </script>
        </head>
        <body>
            <div id="breadcrumb">
                <a href="http://test.ala.org.au">Home</a>
                <a href="http://test.ala.org.au/explore">Explore</a>
                Your Area
            </div>
            <div id="decoratorBody">
                <h2>Explore Your Area</h2>
                <div id="mapOuter" style="width: 400px; height: 450px; float:right;">
                    <div id="yourMap"></div>
                    <div style="font-size:11px;width:400px;">
                        <table id="cellCountsLegend">
                            <tr>
                                <td style="background-color:#333; color:white; text-align:right;">Records:&nbsp;</td>
                                <td style="width:60px;background-color:#ffff00;">1&ndash;9</td>
                                <td style="width:60px;background-color:#ffcc00;">10&ndash;49</td>
                                <td style="width:60px;background-color:#ff9900;">50&ndash;99</td>
                                <td style="width:60px;background-color:#ff6600;">100&ndash;249</td>
                                <td style="width:60px;background-color:#ff3300;">250&ndash;499</td>
                                <td style="width:60px;background-color:#cc0000;">500+</td>
                            </tr>
                        </table>
                    </div>
                </div>
                <div id="left-col">
                    <form name="searchForm" id="searchForm" action="" method="GET" autocomplete="off">
                        <div id="locationInput">
                            <h4>Enter your location or address:</h4>
                            <input name="address" id="address" size="50" value="${address}"/>
                            <input id="locationSearch" type="submit" value="Search"/>
                            <input type="hidden" name="latitude" id="latitude" value="${latitude}"/>
                            <input type="hidden" name="longitude" id="longitude" value="${longitude}"/>
                            <input type="hidden" name="location" id="location" value="${location}"/>
                        </div>
                        <div id="locationInfo">
                            <c:if test="${not empty location}">
                                <p>Showing records for: <b>${location}</b></p>
                            </c:if>
                            <p>Display records in a
                                <select id="radius" name="radius">
                                    <option value="1" <c:if test="${radius eq '1'}">selected</c:if>>1</option>
                                    <option value="5" <c:if test="${radius eq '5'}">selected</c:if>>5</option>
                                    <option value="10" <c:if test="${radius eq '10'}">selected</c:if>>10</option>
                                </select> km radius <!--<input type="submit" value="Reload"/>-->
                            <button id="download" title="Download all species as XLS (tab-delimited) file">Download</button>
                        </div>
                        <div id="taxaBox">
                            <div id="rightList">
                                <div id="thead">Species</div>
                                <div id="taxa-level-1">
                                    <div id="taxaDiv"></div>
                                </div>
                            </div>
                            <div id="leftList">
                                <table id="taxa-level-0">
                                    <thead>
                                        <tr>
                                            <th>Group</th>
                                            <th>Count</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td><a href="*" id="*" class="taxonBrowse">All Species</a>
                                            <td>${fn:length(allLife)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Animalia" id="kingdom" class="taxonBrowse">Animals</a>
                                            <td>${fn:length(animals)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Mammalia" id="class" class="taxonBrowse">Mammals</a></td>
                                            <td>${fn:length(mammals)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Aves" id="class" class="taxonBrowse">Birds</a></td>
                                            <td>${fn:length(birds)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Reptilia" id="class" class="taxonBrowse">Reptiles</a></td>
                                            <td>${fn:length(reptiles)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Amphibia" id="class" class="taxonBrowse">Amphibians</a></td>
                                            <td>${fn:length(frogs)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Agnatha|Chondrichthyes|Osteichthyes" id="class" class="taxonBrowse">Fish</a></td>
                                            <td>${fn:length(fish)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent2"><a href="Insecta" id="class" class="taxonBrowse">Insects</a></td>
                                            <td>${fn:length(insects)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Plantae" id="kingdom" class="taxonBrowse">Plants</a></td>
                                            <td>${fn:length(plants)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Fungi" id="kingdom" class="taxonBrowse">Fungi</a></td>
                                            <td>${fn:length(fungi)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Chromista" id="kingdom" class="taxonBrowse">Chromista</a></td>
                                            <td>${fn:length(chromista)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Protozoa" id="kingdom" class="taxonBrowse">Protozoa</a></td>
                                            <td>${fn:length(protozoa)}</td>
                                        </tr>
                                        <tr>
                                            <td class="indent"><a href="Bacteria" id="kingdom" class="taxonBrowse">Bacteria</a></td>
                                            <td>${fn:length(bacteria)}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </body>
    </html>
