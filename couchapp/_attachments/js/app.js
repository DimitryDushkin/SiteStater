var webserverUrl = "http://"+ location.hostname +":8000";
var closeModalButton = '<a class="close-reveal-modal">&#215;</a>';
var $db, $usersDb, viewModel;
var chartOptions = {
		   chart: {
			   defaultSeriesType: 'line',
			   renderTo: 'chart_container',
			   type: 'spline'
		   },
		   title: {text:'График доступности сайта'},
		   xAxis: {
			   type: 'datetime'
		   },
		   tooltip: {
				formatter: function() {
		                return Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', this.x) +'<br />'
		                	   + '<b>ping</b>: ' + this.y;
				}
			},
		   yAxis: {
			   title: {
		           text: 'ping, мс'
		        }
		   },
		   series: [{
		   	  name: "ping",
			  tooltip: {
				  yDecimals: 2
			  },
		      data : []
		   }],
		   legend: {
				enabled: false
		   }
		};

$(function(){   
	//set variables
	$db = $.couch.db('site_stater');
	
	//site entry in user's sites list
	var siteObject = function(url, lastChecked, status){
		this.url = url;
		this.lastChecked = (lastChecked == 'undefined') ? '' : lastChecked;
		this.status = (status == 'undefined') ? 'not_checked_yet' : status;
		this.toDelete = false;
		this.remove = function() {viewModel.sites.remove(this)};
		//============= Charting stuff =========================
		this.showSiteStat = function() {			
			var ping;
			var url = this.url;
			var dateFrom = new Date().getTime() - 1000*60*60*24*30; // 1 month
			var dateTo = new Date().getTime();
			// clean chart data
			//chartOptions.series[0].data = [];
			//chartOptions.xAxis.categories = [];
			// get stats
			var yData = [];
			var xData = []
			var chartData = [];
			$db.view("app/get-stat-by-site-url-and-timestamp", {
				startkey: [url, dateFrom], //1 day
				endkey: [url, dateTo],
				success: function(data) {
					$.each(data.rows, function(i, row) {
						row.value.status == 200 ? ping = row.value.ping : ping = 0;
						chartData.push([row.value.timestamp, ping]);
					});
		
					chartOptions.series[0].data = chartData;
					
					// render
					// @TODO: place chart after selected site
					// @TODO: get switch range code from early version
					//$("#chart_container").appendTo($(this));
					window.chart = new Highcharts.Chart(chartOptions);
				}
			});
			
			
		};
			
	};
	
	viewModel = {
		//=========== authentication and authorization =============
		userEmail: ko.observable(""),
		showLoginForm: function(event){
			$('#ajax_content').load('templates/login_register.html', function(){
								$(this).append(closeModalButton);
							  })
							  .reveal({animation: "flow_out_off_link",
									   target_link: event.target});				  
		},
		logOut: function(){
			$.couch.logout();
			this.userEmail(null);
		},
		//=========== sites list managment ==========================
		sites: ko.observableArray(),
		//content of #add_site_form input[name="site"]
		siteToAddUrl: ko.observable(),
		//save new sites list to user's list in DB
		saveSitesListToDb: function() {
			var tmp = this.sites();
			$db.openDoc(this.userEmail(), {
				success: function(response) {
					response.sites = $.map(tmp, function(site){return site.url});
					$db.saveDoc(response);
				}
			});
		},
		//on "add site" button click
		showAddSiteForm: function() {
			if ($('#remove_sites_form').is(":visible"))
				$('#remove_sites_form').slideUp();
			
			$('#add_site_form').slideToggle()
							   .find('input[name="site"]')
							   .val("http://")
							   .focus();
		},
		//on "add" click in "add site" form
		addSite: function(){
			//======== nifty hack(( ======
			var sites = this.sites();
			sites.push(new siteObject(this.siteToAddUrl()));
			this.sites(sites);
			//======= end of hack ========
			
			//add to sites' the check list if it's not already there
			var siteUrl = this.siteToAddUrl();
			$db.openDoc(siteUrl, {
				error: function(code){
					$db.saveDoc({_id: siteUrl, type: 'site'})
				}
			});
			
			//save new sites list to user's list in DB
			this.saveSitesListToDb();
			
			$('#add_site_form').slideToggle();
		},
		//on "remove sites" button click
		showRemoveSitesForm: function() {
			if ($('#add_site_form').is(":visible"))
				$('#add_site_form').slideUp();
			
			$('#remove_sites_form').slideToggle();
			
			//toggle checkboxes
			$('#content_sites_list .site_info input[type="checkbox"]').slideToggle();		
		},
		//on "remove sites" button click
		removeSites: function() {
			var sitesToRemove = [];
			$.each(this.sites(), function(){
				if (this.toDelete) sitesToRemove.push(this);
			});
			if (sitesToRemove.length == 0)
				alert("Ни одного сайта не было выбрано для удаления.");
			else {
				var message = "Вы точно хотите перестать отслеживать";
				for (var i in sitesToRemove) {
					message += "\n\"" +  sitesToRemove[i].url + "\"";
				}
				message += "?";
				if (confirm(message)) {
					$.each(sitesToRemove, function(){this.remove()});
					//save new sites list to db
					this.saveSitesListToDb();
				}
			}	
			//hide form
			$('#remove_sites_form').slideToggle();
			//toggle checkboxes
			$('#content_sites_list .site_info input[type="checkbox"]').slideToggle();
		},
		cancelRemoveSites: function() {
			$('#remove_sites_form').slideToggle();
			$('#content_sites_list .site_info input[type="checkbox"]').slideToggle()
																	  .attr("checked", false);
		},
		//================ some fancy animation on sites' list ======================
		animationOnAddSite: function(el) {
			$(el).hide().delay(Math.floor(Math.random()*800)).fadeIn('slow')
		},
		animationOnRemoveSite: function(el) {
			$(el).animate({'marginLeft':'+=100', opacity: 0, height: 0}, 500, function(){
				$(this).empty();
			})
		}
	};
	
	/*
	 * If user is logged in, load sites concerning stuff
	 * else show "about" page
	 */
	viewModel.userEmail.subscribe(function(newValue) {
		if (this.userEmail()) {
			$('#content').load('templates/sites_panel.html',
				function() {ko.applyBindings(viewModel)}
			);
			$db.view('app/get-sites-list-by-user', {
				type: 'json',
				key: this.userEmail(),
				include_docs: true,
				success: function(data) {
					var tmp = [];
					$.each(data.rows, function(i, row) {
						var dateTimestamp = new Date(row.doc.timestamp).toLocaleString();
						var site = new siteObject(row.doc._id, dateTimestamp, row.doc.status);
						tmp.push(site);
					});
					viewModel.sites(tmp);
				}
			});
		} else {
			$('#content').load('templates/about.html');
		}
	}, viewModel);
	
	
	ko.applyBindings(viewModel);
	
	/*======================== App start routine ======================================*/
	//1. Get server status
	$.ajax({
		url: webserverUrl + '/server/',
		type: "get",
		dataType: "json",
		success: function(data) {
			if (data.server_status == "up")
				$('#control_server_button').append(' <img src="img/green_light.png"' + 
												   'alt="Server is on"' +
												   'title="Сервер работает. Статистика собирается!)"' +
												   'class="server_status_light"/>');				
		},
		error: function(jqXHR, text) {
			$('#control_server_button').append(' <img src="img/red_light.png"' + 
					  'alt="Server is off." title="Server is down. Reason: ' + text + '"' + 
					  'class="server_status_light"/>');
		}
	});
	//2. Check user already logged it
	$.couch.session({
        success : function(r) {
            var userCtx = r.userCtx;
            if (userCtx.name) {
                viewModel.userEmail(userCtx.name);
            } else {
            	$('#content').load('templates/about.html');
            }
        }
    });
});