// Set the paramaters below (observation period, search area, and max cloud cover are most important)
// Navigate to the MADAS webpage at https://gbank.gsj.jp/madas/map/index.html
// Open the developer console (in the same browser tab). In chrome use Command+Option+J (Mac) or Control+Shift+J (Windows, Linux)
// Paste the code below (or drag and drop this .js file) into the javascript console and hit enter to download a text file containing the list of ASTER scene urls
// Use a bulk download program to download the data (wget, curl, the "Tab Save" chrome extension, etc.)

// Ajax call to MADAS database
$.ajax({
    dataType: "xml",
    contentType: 'application/json; charset=utf-8',
    data: {

        // Max Number of Records, Page, Start Pos
        max_record: 999,
        page: 1,
        base0: 0,

        // Base Map [ 0: lonlat , 1: m(north) , 2: m(south) ]
        base1: 0,

        // Sort
        sort: "DESC",

        // Satellite Sensors [TRUE or ""]
        satellite: "ASTER",
        satellite_aster: "TRUE",
        satelilte_jers1ops: "",
        satelilte_jers1sar: "",

        // Observation Period [yyyy-mm-dd HH:MM:ss]
        start: "1999-01-01 00:00:00",
        end: "2020-12-31 00:00:00",

        // Search Area [ N,W,E,S(999.9999) ]
        maxy: "28.2",
        minx: "90.2",
        maxx: "90.3",
        miny: "28.1",

        // Granule ID [ TTTTTTTTTTTTT ]
        gid: "",
        // Operational Mode
        aster_op_mode: "V",
        // Day or Night
        ASTER5: "TRUE",
        ASTER6: "FALSE",
        // Illumination Elevation Angle [ From ]
        ASTER7: "",
        // Illumination Elevation Angle [ To ]
        ASTER8: "",
        // Max Cloud Cover [ 10 - 100 % ]
        aster_cloud: "100",
        // Pointing Angle [ From ]
        ASTER10: "",
        // Pointing Angle [ To ]
        ASTER11: "",

        // JERS-1 (OPS)
        // Operational Mode [ 1:Full 2:VNIR 3:SWIR ]
        OPS1: "",
        OPS2: "",
        // Day or Night
        OPS3: "",
        OPS4: "",
        // Illumination Elevation Angle [ From ]
        OPS5: "",
        // Illumination Elevation Angle [ To ]
        OPS6: "",
        // Cloud Cover [ 10 - 100 % ]
        jers1ops_cloud: "",

        // JERS-1 (SAR)
        // Off Nadir Angle [ 8 - 60 ]
        SAR1: "",
        SAR2: ""
    },
    cache: true,
    url: "/madas/cgi-bin/php/SearchCSW.php",
    success: function (data) {

        // Concat urls
        var entrys = $(data).find('entry');
        var text = '';
        for(var i=0;i<entrys.length;i++) {
            var GID = $(entrys[i]).find("id").text();
            var url = "https://aster.geogrid.org/ASTER/fetchL3A/" + GID + ".tar.bz2";
            text += url + "\r\n";
        }
        
        // Download url list as text file
        var element = document.createElement('a');
        element.setAttribute('href','data:text/plain;charset=utf-8,' + encodeURIComponent(text));
        element.setAttribute('download',"madas_url_list.txt");
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();

    },
    error: function () {
        alert("an unexpected error occurred");
    },
    complete: function(){
    }
});
