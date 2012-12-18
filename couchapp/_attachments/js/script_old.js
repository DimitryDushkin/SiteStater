/**
 * @TODO add link validation
 * //@TO-THINK may be swutch to google visualization API
// of flot https://github.com/flot/flot
 */

var chart;
var chartOptions = {
   chart: {
	   defaultSeriesType: 'line'
   },
   title: {text:'График доступности сайта'},
//   subtitle: {
//       text: document.ontouchstart === undefined ?
//          'Click and drag in the plot area to zoom in' :
//          'Drag your finger over the plot to zoom in'
//    },
   xAxis: {
	   type: 'datetime',
       categories: []
   },
   yAxis: {
	   title: {
           text: 'ping, ms'
        }
   },
   series: [{
   	  name: "ping",
      data : []
   }]
};

$(function(){
	/*==================== Settings, events, etc. ===================================*/
	var $db = $.couch.db('site_stater');
	var $content_sites_list = $('#content_sites_list');
	
	/**
	 * Update site list in content zone
	 */
	function update_sites_lists() {
		function doRequest() {
			$db.view('app/get-sites-list', {
				type: 'json',
				success: function(data) {
					$content_sites_list.empty();
					var $template = $('#sites_list_template');
					$.each(data.rows, function(i, site) {
						site.value.url = site.id;
						site.value.dateTimestamp = new Date(site.value.timestamp).toLocaleString();
						$template.tmpl(site.value)
								 .appendTo('#content_sites_list');
					});
					$content_sites_list.fadeIn();
				}
			});			
		}
		$content_sites_list.fadeOut(400, doRequest);
	}
	
	
	//on "server control" button click 
	$("#control_server_button").click(function() {
		
		return false;
	});
	
	/* ======================= Add ===========================*/
	
	//on "add site" button click
	$('#add_site').click(function() {
		if ($('#remove_sites_form').is(":visible"))
			$('#remove_sites_form').slideToggle();
		
		$form = $('#add_site_form');
		$form.slideToggle();
		$form.find('input[name="site"]')
			 .val("http://")
			 .focus();
		
		return false;
	});
	
	//on "add" click in "add site" form
	$('#add_site_form input[type="submit"]').click(function(){
		$form = $(this).parent();
		$.ajax({
			url: webserverUrl + '/sites/',
			type: "get",
			dataType: "json",
			data: {action: "add_site",
				   site: $form.find('input[name="site"]').val()},
			complete: function() {
				update_sites_lists();
			}
		});
		$form.slideToggle();
		
		return false;
	});	
	
	/* ======================= Edit and remove ===========================*/
	
	//on "edit sites list" button click
	$('#edit_sites_list').click(function() {
		if ($('#add_site_form').is(":visible"))
			$('#add_site_form').slideToggle();
		
		$form = $('#remove_sites_form');
		$form.slideToggle();
		
		//toggle checkboxes
		$('#content_sites_list .site_info input[type="checkbox"]').slideToggle();
		
		return false;
	});
	
	//on "remove sites" button click
	$('#remove_sites').click(function(){
		var sites_to_remove = [];
		$('#content_sites_list .site_info input[type="checkbox"]:checked').each(function(){
			sites_to_remove.push($(this).attr("value"));
		});
		if (sites_to_remove.length == 0)
			alert("Ни одного сайта не было выбрано для удаления.");
		else {
			var message = "Вы точно хотите перестать отслеживать";
			for (var i in sites_to_remove) {
				message += "\n" +  sites_to_remove[i];
			}
			message += "?";
			if (confirm(message)) {
				delete_sites(sites_to_remove);
			}
			//fancy animation of deletion
			$('#content_sites_list .site_info input[type="checkbox"]:checked')
					.parent().parent().parent()
					.animate({
						'marginLeft':'+=100',
						opacity: 0
					}, 500, function(){
						$(this).empty();
					});
		}	
		
		$('#remove_sites_form').slideToggle();
		//toggle checkboxes
		$('#content_sites_list .site_info input[type="checkbox"]').slideToggle();
		
		return false;
	});
	
	//on "cancel remove" click
	$('#cancel_remove_sites').click(function(){
		$('#remove_sites_form').slideToggle();
		$('#content_sites_list .site_info input[type="checkbox"]').slideToggle()
																  .attr("checked", false);
	});
	
	function delete_sites(sites) {
		for (var i in sites)
			$.ajax({
				async: false,
				url: webserverUrl + '/sites/',
				type: "get",
				dataType: "json",
				data: {action: "remove_site",
					   site: sites[i]}
			});	
	}
	/* ======================= END Edit and remove ===========================*/
	
	/*======================= Chart stuff ===============================*/
	/**
	 * Fills #chartContainer with data
	 * 
	 */
	function fill_chart(url, dateFrom, dateTo) {
		var ping;
		// clean chart data
		chartOptions.series[0].data = [];
		chartOptions.xAxis.categories = [];
		// get stats
		$db.view("app/get-stat-by-site-url-and-timestamp", {
			startkey: [url, dateFrom], //1 day
			endkey: [url, dateTo],
			success: function(data) {
				$.each(data.rows, function(i, row) {
					row.value.status == 200 ? ping = row.value.ping : ping = 0;
					chartOptions.series[0].data.push(ping);
					chartOptions.xAxis.categories.push(row.value.timestamp);
				});
				// prepare chart
				chartOptions.chart.renderTo = 'chartContainer';
				
				// render
				chart = new Highcharts.Chart(chartOptions);
			}
		});
	}
	
	//on url click – show site stat for one day
	$("#content").delegate('.show_site_stat', 'click', function(){
		var dateFrom = new Date().getTime() - 1000*60*60*24;
		var dateTo = new Date().getTime();
		var url = $(this).attr('href');
		var $siteStat = $(this).closest('.site_panel').find('.site_stat');
		fill_chart(url, dateFrom, dateTo);
		$("#chartContainer").appendTo($siteStat);
		$("#content").find('.site_stat').hide();
		$siteStat.slideDown();
		
		return false;
	});
	
	//on range buttons click
	$("#content").delegate('.stat_range a', 'click', function(){
		$(this).parent().find('a').removeClass('stat_range_selected');
		$(this).addClass('stat_range_selected');
		var rangeInMs = parseInt($(this).data('range')) * 1000*60*60*24;
		var dateFrom = new Date().getTime() - rangeInMs;
		var dateTo = new Date().getTime();
		var url = $(this).closest('.site_panel')
						 .find('.show_site_stat')
						 .attr('href');
		fill_chart(url, dateFrom, dateTo);
		
		return false;
	});
	
	/*======================= End Chart stuff ===============================*/
	
	
	/*======================== App start routine ======================================*/
	//1. Get server status
	var webserverUrl = "http://"+ location.hostname +":8000";
	$.ajax({
		url: webserverUrl + '/server/',
		type: "get",
		dataType: "json",
		success: function(data) {
			if (data.server_status == "up")
				$('#control_server_button').append(' <img src="img/green_light.png"' + 
														  'alt="Server is on"' + 
														  'class="server_status_light"/>');				
		},
		error: function(jqXHR, text) {
			$('#control_server_button').append(' <img src="img/red_light.png"' + 
					  'alt="Server is off." title="Server is off. Reason: ' + text + '"' + 
					  'class="server_status_light"/>');
		}
	});
	
	//2. Update sites lists
	update_sites_lists();		
	
});