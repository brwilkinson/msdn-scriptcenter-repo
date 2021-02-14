---
layout: null
---
(function () {
	function getQueryVariable(variable) {
		var query = window.location.search.substring(1),
			vars = query.split("&");

		for (var i = 0; i < vars.length; i++) {
			var pair = vars[i].split("=");

			if (pair[0] === variable) {
				return pair[1];
			}
		}
	}

	function getPreview(query, content, previewLength) {
		previewLength = previewLength || (content.length * 2);

		var parts = query.split(" "),
			match = content.toLowerCase().indexOf(query.toLowerCase()),
			matchLength = query.length,
			preview;

		// Find a relevant location in content
		for (var i = 0; i < parts.length; i++) {
			if (match >= 0) {
				break;
			}

			match = content.toLowerCase().indexOf(parts[i].toLowerCase());
			matchLength = parts[i].length;
		}

		// Create preview
		if (match >= 0) {
			var start = match - (previewLength / 2),
				end = start > 0 ? match + matchLength + (previewLength / 2) : previewLength;

			preview = content.substring(start, end).trim();

			if (start > 0) {
				preview = "..." + preview;
			}

			if (end < content.length) {
				preview = preview + "...";
			}

			// Highlight query parts
			preview = preview.replace(new RegExp("(" + parts.join("|") + ")", "gi"), "<strong>$1</strong>");
		} else {
			// Use start of content if no match found
			preview = content.substring(0, previewLength).trim() + (content.length > previewLength ? "..." : "");
		}

		return preview;
	}

	function displaySearchResults(results, query) {
		var searchResultsEl = document.getElementById("search-results"),
			searchProcessEl = document.getElementById("search-process");

		if (results.length) {
			var resultsHTML = "";
			results.forEach(function (result) {
				var item = window.data[result.ref],
					contentPreview = getPreview(query, item.content, 170),
					titlePreview = getPreview(query, item.title);

				// resultsHTML += "<li style='list-style-type:none;'><a class='search-result-title' href='" + item.url.trim() + "'>" + titlePreview + "</a><p style='font-size:smaller;'>" + contentPreview + "</p></li>";

				// resultsHTML += "<li style='list-style-type:none;'><a class='search-result-title' href='" + item.url.trim() + "'>" + titlePreview + "</a><p style='font-size:smaller;'>" + contentPreview + "</p></li>";

resultsHTML += `
				<table>
					<tr id="myColor">
					<th colspan=1>Title</th>
					<th colspan=4>${ item.title }</th>
					</tr>
					<tr>
					<th colspan=1>Description</th>
					<td colspan=4>${ item.content }</td>
					</tr>
					<tr>
					<th rowspan = 2>Script</th>
					<th>ModifiedDate</th>
					<td>${ item.modifieddate }</td>
					<th>CreatedDate</th>
					<td>${ item.createddate }</td>
					</tr>
					<tr>
					<th>RatingsCount</th>
					<td>${ item.ratingscount }</td>
					<th>AverageRating</th>
					<td>${ item.averagerating }</td>
					</tr>
					<tr>
					<th colspan=1>ProjectName</th>
					<td colspan=2>${ item.projectname }</td>
					<th>ProjectID</th>
					<td>${ item.projectid }</td>
					</tr>
					<tr>
					<th colspan=1>GitHub Path</th>
					<td colspan=4><a href="${item.site }/artifacts/${ item.projectid }/">${item.site }/artifacts/${ item.projectid }</a></td>
					</tr>
					<tr>
					<th colspan=1>GitHub View</th>
					<td colspan=4><a href="${item.site }/artifacts/${ item.projectid }/${item.scriptfile}">${item.scriptfile}</a></td>
					</tr>
					<tr>
					<th colspan=1>TagList</th>
					<td colspan=4>${ item.taglist }</td>
					</tr>
				</table>
				<br/>
			`;


			});

			searchResultsEl.innerHTML = resultsHTML;
			searchProcessEl.innerText = "Found some";
		} else {
			searchResultsEl.style.display = "none";
			searchProcessEl.innerText = "No ";
		}
	}

	window.index = lunr(function () {
		this.field("id");
		this.field("title", {boost: 10});
		this.field("categories");
		this.field("url");
		this.field("content");
		this.field("modifieddate");
		this.field("createddate");
		this.field("ratingscount");
		this.field("averagerating");
		this.field("projectname");
		this.field("projectid");
		this.field("scriptfile");
		this.field("site");
		this.field("taglist");
	});

	var query = decodeURIComponent((getQueryVariable("q") || "").replace(/\+/g, "%20")),
		searchQueryContainerEl = document.getElementById("search-query-container"),
		searchQueryEl = document.getElementById("search-query");

	searchQueryEl.innerText = query;
	searchQueryContainerEl.style.display = "inline";

	for (var key in window.data) {
		window.index.add(window.data[key]);
	}

	displaySearchResults(window.index.search(query), query); // Hand the results off to be displayed
})();
