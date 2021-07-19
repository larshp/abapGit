/**********************************************************
 * ABAPGIT JS function library
 **********************************************************/

/**********************************************************
  Global variables used from outside
 **********************************************************/
/* exported setInitialFocus */
/* exported setInitialFocusWithQuerySelector */
/* exported submitFormById */
/* exported errorStub */
/* exported confirmInitialized */
/* exported perfOut */
/* exported perfLog */
/* exported perfClear */
/* exported enableArrowListNavigation */
/* exported activateLinkHints */
/* exported setKeyBindings */
/* exported preparePatch */
/* exported registerStagePatch */
/* exported toggleRepoListDetail */
/* exported onTagTypeChange */
/* exported getIndocStyleSheet */
/* exported addMarginBottom */
/* exported enumerateJumpAllFiles */
/* exported createRepoCatalogEnumerator */
/* exported enumerateToolbarActions */
/* exported onDiffCollapse */
/* exported restoreScrollPosition */

/**********************************************************
 * Polyfills
 **********************************************************/

// Bind polyfill (for IE7), taken from https://developer.mozilla.org/
if (!Function.prototype.bind) {
  Function.prototype.bind = function(oThis) {
    if (typeof this !== "function") {
      throw new TypeError("Function.prototype.bind - subject is not callable");
    }

    var aArgs   = Array.prototype.slice.call(arguments, 1),
      fToBind = this,
      fNOP    = function() {},
      fBound  = function() {
        return fToBind.apply(
          this instanceof fNOP
            ? this
            : oThis,
          aArgs.concat(Array.prototype.slice.call(arguments))
        );
      };

    if (this.prototype) {
      fNOP.prototype = this.prototype;
    }
    fBound.prototype = new fNOP();

    return fBound;
  };
}

// String includes polyfill, taken from https://developer.mozilla.org
if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    "use strict";
    if (typeof start !== "number") {
      start = 0;
    }

    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}

// String startsWith polyfill, taken from https://developer.mozilla.org
if (!String.prototype.startsWith) {
  Object.defineProperty(String.prototype, "startsWith", {
    value: function(search, pos) {
      pos = !pos || pos < 0 ? 0 : +pos;
      return this.substring(pos, pos + search.length) === search;
    }
  });
}

// forEach polyfill, taken from https://developer.mozilla.org
// used for querySelectorAll results
if (window.NodeList && !NodeList.prototype.forEach) {
  NodeList.prototype.forEach = Array.prototype.forEach;
}

/**********************************************************
 * Common functions
 **********************************************************/

// Output text to the debug div
function debugOutput(text, dstID) {
  var stdout       = document.getElementById(dstID || "debug-output");
  var wrapped      = "<p>" + text + "</p>";
  stdout.innerHTML = stdout.innerHTML + wrapped;
}

// Use a pre-created form or create a hidden form
// and submit with sapevent
function submitSapeventForm(params, action, method) {

  function getSapeventPrefix() {
    if (document.querySelector('a[href*="file:///SAPEVENT:"]'))  {
      return "file:///"; //Prefix for chromium based browser control
    } else {
      return "";
    }
  }

  var stub_form_id = "form_" + action;
  var form = document.getElementById(stub_form_id);

  if (form === null) {
    form = document.createElement("form");
    form.setAttribute("method", method || "post");
    if (/sapevent/i.test(action)){
      form.setAttribute("action", action);
    } else {
      form.setAttribute("action", getSapeventPrefix() + "SAPEVENT:" + action);
    }
  }

  for(var key in params) {
    var hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("name", key);
    hiddenField.setAttribute("value", params[key]);
    form.appendChild(hiddenField);
  }

  if (form.id !== stub_form_id) {
    document.body.appendChild(form);
  }

  form.submit();
}

// Set focus to a control
function setInitialFocus(id) {
  document.getElementById(id).focus();
}

// Set focus to a element with query selector
function setInitialFocusWithQuerySelector(sSelector, bFocusParent) {
  var oSelected = document.querySelector(sSelector);

  if (oSelected) {
    if (bFocusParent) {
      oSelected.parentElement.focus();
    } else {
      oSelected.focus();
    }
  }

}

// Submit an existing form
function submitFormById(id) {
  document.getElementById(id).submit();
}

// JS error stub
function errorStub(event) {
  var element    = event.target || event.srcElement;
  var targetName = element.id || element.name || "???";
  alert("JS Error, please log an issue (@" + targetName + ")");
}

// confirm JS initilization
function confirmInitialized() {
  var errorBanner = document.getElementById("js-error-banner");
  if (errorBanner) {
    errorBanner.style.display = "none";
  }
  debugOutput("js: OK"); // Final final confirmation :)
}

/**********************************************************
 * Performance utils (for debugging)
 **********************************************************/

var gPerf = [];

function perfOut(prefix) {
  var totals = {};
  for (var i = gPerf.length - 1; i >= 0; i--) {
    if (!totals[gPerf[i].name]) totals[gPerf[i].name] = {count: 0, time: 0};
    totals[gPerf[i].name].time  += gPerf[i].time;
    totals[gPerf[i].name].count += 1;
  }

  var keys = Object.keys(totals);
  for (var j = keys.length - 1; j >= 0; j--) {
    console.log(prefix
      + " " + keys[j] + ": "
      + totals[keys[j]].time.toFixed(3) + "ms"
      + " (" + totals[keys[j]].count.toFixed() +")");
  }
}

function perfLog(name, startTime) {
  gPerf.push({name: name, time: window.performance.now() - startTime});
}

function perfClear() {
  gPerf = [];
}

/**********************************************************
 * TAG PAGE Logic
 **********************************************************/
function onTagTypeChange(oSelectObject){
  var sValue = oSelectObject.value;
  submitSapeventForm({ type: sValue }, "change_tag_type", "post");
}

/**********************************************************
 * Repo Overview Logic
 **********************************************************/
function findStyleSheetByName(name) {
  for (var s = 0; s < document.styleSheets.length; s++) {
    var styleSheet = document.styleSheets[s];
    var classes    = styleSheet.cssRules || styleSheet.rules;
    for (var i = 0; i < classes.length; i++) {
      if (classes[i].selectorText === name) return classes[i];
    }
  }
}

function getIndocStyleSheet() {
  for (var s = 0; s < document.styleSheets.length; s++) {
    if (!document.styleSheets[s].href) return document.styleSheets[s]; // One with empty href
  }
  // None found ? create one
  var style = document.createElement("style");
  document.head.appendChild(style);
  return style.sheet;
}

function RepoOverViewHelper() {
  this.setHooks();
  this.pageId = "RepoOverViewHelperState"; // constant is OK for this case
  this.isDetailsDisplayed = false;
  this.isOnlyFavoritesDisplayed = false;
  this.detailCssClass = findStyleSheetByName(".ro-detail");
  this.actionCssClass = findStyleSheetByName(".ro-action");
  var icon = document.getElementById("icon-filter-detail");
  this.toggleFilterIcon(icon, this.isDetailsDisplayed);
  icon = document.getElementById("icon-filter-favorite");
  this.toggleFilterIcon(icon, this.isOnlyFavoritesDisplayed);
  this.registerRowSelection();
  this.registerKeyboardShortcuts();
}

RepoOverViewHelper.prototype.setHooks = function () {
  window.onload = this.onPageLoad.bind(this);
};

RepoOverViewHelper.prototype.onPageLoad = function () {
  var data = window.localStorage && JSON.parse(window.localStorage.getItem(this.pageId));
  if (data) {
    if (data.isDetailsDisplayed) {
      this.toggleItemsDetail(true);
    }
    if (data.isOnlyFavoritesDisplayed) {
      this.toggleItemsFavorites(true);
    }
    if (data.selectedRepoKey) {
      this.selectRowByRepoKey(data.selectedRepoKey);
    } else {
      this.selectRowByIndex(0);
    }
  }
};

RepoOverViewHelper.prototype.registerKeyboardShortcuts = function() {
  var self = this;
  document.addEventListener("keypress", function(event) {
    if (document.activeElement.id === "filter") {
      return;
    }
    var keycode = event.keyCode;
    var rows = Array.prototype.slice.call(self.getVisibleRows());
    var selected = document.querySelector(".repo.selected");
    var indexOfSelected = rows.indexOf(selected);

    if (keycode == 13 && // "enter" to open
       document.activeElement.tagName.toLowerCase() != "input") { // prevent opening if command field has focus
      self.openSelectedRepo();
    } else if ((keycode == 52 || keycode == 100) && indexOfSelected > 0) {
      // "4" for previous
      self.selectRowByIndex(indexOfSelected - 1);
    } else if ((keycode == 54 || keycode == 102) && indexOfSelected < rows.length - 1) {
      // "6" for next
      self.selectRowByIndex(indexOfSelected + 1);
    }
  });
};

RepoOverViewHelper.prototype.openSelectedRepo = function () {
  this.selectedRepoKey = document.querySelector(".repo.selected").dataset.key;
  this.saveLocalStorage();
  document.querySelector(".repo.selected td.ro-go a").click();
};

RepoOverViewHelper.prototype.selectRowByIndex = function (index) {
  var rows = this.getVisibleRows();
  if (rows.length >= index) {
    var selectedRow = rows[index];
    if (selectedRow.classList.contains("selected")) {
      return;
    }

    this.deselectAllRows();
    rows[index].classList.add("selected");
    this.selectedRepoKey = selectedRow.dataset.key;
    this.updateActionLinks(selectedRow);
    this.saveLocalStorage();
  }
};

RepoOverViewHelper.prototype.selectRowByRepoKey = function (key) {
  var attributeQuery = "[data-key='" + key + "']";
  var row = document.querySelector(".repo" + attributeQuery);
  // navigation to already selected repo
  if (row.dataset.key === key && row.classList.contains("selected")) {
    return;
  }

  this.deselectAllRows();
  row.classList.add("selected");
  this.selectedRepoKey = key;
  this.updateActionLinks(row);
  this.saveLocalStorage();
};

RepoOverViewHelper.prototype.updateActionLinks = function (selectedRow) {
  // now we have a repo selected, determine which action buttons are relevant
  var selectedRepoKey = selectedRow.dataset.key;
  var selectedRepoIsOffline = selectedRow.dataset.offline === "X";

  var actionLinks = document.querySelectorAll("a.action_link");
  actionLinks.forEach(function (link) {
    // adjust repo key in urls
    link.href = link.href.replace(/\?key=(#|\d+)/, "?key=" + selectedRepoKey);

    // toggle button visibility
    if (link.classList.contains("action_offline_repo")) {
      if (selectedRepoIsOffline) {
        link.parentElement.classList.add("enabled");
      } else {
        link.parentElement.classList.remove("enabled");
      }
    }
    else if (link.classList.contains("action_online_repo")) {
      if (!selectedRepoIsOffline) {
        link.parentElement.classList.add("enabled");
      } else {
        link.parentElement.classList.remove("enabled");
      }
    }
    else {
      // if the action is for both repository types, it will only have the .action_link class
      // it still needs to be toggled as we want to hide everything if no repo is selected
      link.parentElement.classList.add("enabled");
    }
  });
};

RepoOverViewHelper.prototype.deselectAllRows = function () {
  document.querySelectorAll(".repo").forEach(function (x) {
    x.classList.remove("selected");
  });
};

RepoOverViewHelper.prototype.getVisibleRows = function () {
  return document.querySelectorAll(".repo:not(.nodisplay)");
};

RepoOverViewHelper.prototype.registerRowSelection = function () {
  var self = this;
  document.querySelectorAll(".repo td:not(.ro-go)").forEach(function (repoListRowCell) {
    repoListRowCell.addEventListener("click", function () {
      self.selectRowByRepoKey(this.parentElement.dataset.key);
    });
  });

  document.querySelectorAll(".repo td.ro-go").forEach(function (openRepoIcon) {
    openRepoIcon.addEventListener("click", function () {
      var selectedRow = this.parentElement;
      self.selectRowByRepoKey(selectedRow.dataset.key);
      self.openSelectedRepo();
    });
  });
};

RepoOverViewHelper.prototype.toggleRepoListDetail = function (forceDisplay) {
  if (this.detailCssClass) {
    this.toggleItemsDetail(forceDisplay);
    this.saveLocalStorage();
  }
};

RepoOverViewHelper.prototype.toggleItemsDetail = function (forceDisplay) {
  if (this.detailCssClass) {
    this.isDetailsDisplayed = forceDisplay || !this.isDetailsDisplayed;

    // change layout to wide if details are displayed
    if (this.isDetailsDisplayed) {
      document.body.classList.remove("centered");
      document.body.classList.add("full_width");
    } else {
      document.body.classList.add("centered");
      document.body.classList.remove("full_width");
    }

    this.detailCssClass.style.display = this.isDetailsDisplayed ? "" : "none";
    var icon = document.getElementById("icon-filter-detail");
    this.toggleFilterIcon(icon, this.isDetailsDisplayed);
  }
};

RepoOverViewHelper.prototype.toggleFilterIcon = function (icon, isEnabled) {
  if (isEnabled) {
    icon.classList.remove("grey");
    icon.classList.add("blue");
  } else {
    icon.classList.remove("blue");
    icon.classList.add("grey");
  }
};

RepoOverViewHelper.prototype.toggleRepoListFavorites = function (forceDisplay) {
  this.toggleItemsFavorites(forceDisplay);
  this.saveLocalStorage();
};

RepoOverViewHelper.prototype.toggleItemsFavorites = function (forceDisplay) {
  this.isOnlyFavoritesDisplayed = forceDisplay || !this.isOnlyFavoritesDisplayed;
  var repositories = document.getElementsByClassName("repo");
  var icon = document.getElementById("icon-filter-favorite");
  this.toggleFilterIcon(icon, this.isOnlyFavoritesDisplayed);
  for (var i = 0; i < repositories.length; i++) {
    var repo = repositories[i];
    if (this.isOnlyFavoritesDisplayed) {
      if (!repo.classList.contains("favorite")) {
        repo.classList.add("nodisplay");
      }
    } else {
      repo.classList.remove("nodisplay");
    }
  }
};

RepoOverViewHelper.prototype.saveLocalStorage = function () {
  if (!window.localStorage) return;
  var data = {
    isDetailsDisplayed: this.isDetailsDisplayed,
    isOnlyFavoritesDisplayed: this.isOnlyFavoritesDisplayed,
    selectedRepoKey: this.selectedRepoKey,
  };
  window.localStorage.setItem(this.pageId, JSON.stringify(data));
};


/**********************************************************
 * STAGE PAGE Logic
 **********************************************************/

// Stage helper constructor
function StageHelper(params) {
  this.pageSeed        = params.seed;
  this.formAction      = params.formAction;
  this.patchAction     = params.patchAction;
  this.user            = params.user;
  this.selectedCount   = 0;
  this.filteredCount   = 0;
  this.lastFilterValue = "";

  // DOM nodes
  this.dom = {
    stageTab:          document.getElementById(params.ids.stageTab),
    commitAllBtn:      document.getElementById(params.ids.commitAllBtn),
    commitSelectedBtn: document.getElementById(params.ids.commitSelectedBtn),
    commitFilteredBtn: document.getElementById(params.ids.commitFilteredBtn),
    patchBtn:          document.getElementById(params.ids.patchBtn),
    objectSearch:      document.getElementById(params.ids.objectSearch),
    selectedCounter:   null,
    filteredCounter:   null,
  };
  this.findCounters();

  // Table columns (autodetection)
  this.colIndex      = this.detectColumns();
  this.filterTargets = ["name", "user", "transport"];

  // Constants
  this.HIGHLIGHT_STYLE = "highlight";
  this.STATUS = {
    add:    "A",
    remove: "R",
    ignore: "I",
    reset:  "?",
    isValid: function (status) { return "ARI?".indexOf(status) == -1 }
  };

  this.TEMPLATES = {
    cmdReset:  "<a>reset</a>",
    cmdLocal:  "<a>add</a>",
    cmdRemote: "<a>ignore</a><a>remove</a>"
  };

  this.setHooks();
  if (this.user) this.injectFilterMe();
  Hotkeys.addHotkeyToHelpSheet("^Enter", "Commit");
  this.dom.objectSearch.focus();
}

StageHelper.prototype.findCounters = function() {
  this.dom.selectedCounter = this.dom.commitSelectedBtn.querySelector("span.counter");
  this.dom.filteredCounter = this.dom.commitFilteredBtn.querySelector("span.counter");
};

StageHelper.prototype.injectFilterMe = function() {
  var tabFirstHead = this.dom.stageTab.tHead.rows[0];
  if (!tabFirstHead || tabFirstHead.className !== "local") {
    return; // for the case only "remove part" is displayed
  }
  var changedByHead = tabFirstHead.cells[this.colIndex.user];
  changedByHead.innerText = changedByHead.innerText + " (";
  var a = document.createElement("A");
  a.appendChild(document.createTextNode("me"));
  a.onclick = this.onFilterMe.bind(this);
  a.href = "#";
  changedByHead.appendChild(a);
  changedByHead.appendChild(document.createTextNode(")"));
};

StageHelper.prototype.onFilterMe = function() {
  this.dom.objectSearch.value = this.user;
  this.onFilter({ type: "keypress", which: 13, target: this.dom.objectSearch });
};

// Hook global click listener on table, load/unload actions
StageHelper.prototype.setHooks = function() {
  window.onkeypress                  = this.onCtrlEnter.bind(this);
  this.dom.stageTab.onclick          = this.onTableClick.bind(this);
  this.dom.commitSelectedBtn.onclick = this.submit.bind(this);
  this.dom.commitFilteredBtn.onclick = this.submitVisible.bind(this);
  this.dom.patchBtn.onclick          = this.submitPatch.bind(this);
  this.dom.objectSearch.oninput      = this.onFilter.bind(this);
  this.dom.objectSearch.onkeypress   = this.onFilter.bind(this);
  window.onbeforeunload              = this.onPageUnload.bind(this);
  window.onload                      = this.onPageLoad.bind(this);
};

// Detect column index
StageHelper.prototype.detectColumns = function() {
  var dataRow  = this.dom.stageTab.tBodies[0].rows[0];
  var colIndex = {};

  for (var i = dataRow.cells.length - 1; i >= 0; i--) {
    if (dataRow.cells[i].className) colIndex[dataRow.cells[i].className] = i;
  }

  return colIndex;
};

// Store table state on leaving the page
StageHelper.prototype.onPageUnload = function() {
  if (!window.sessionStorage) return;

  var data = this.collectData();
  window.sessionStorage.setItem(this.pageSeed, JSON.stringify(data));
};

// Re-store table state on entering the page
StageHelper.prototype.onPageLoad = function() {
  var data = window.sessionStorage && JSON.parse(window.sessionStorage.getItem(this.pageSeed));

  this.iterateStageTab(true, function (row) {
    var status = data && data[row.cells[this.colIndex["name"]].innerText];
    this.updateRow(row, status || this.STATUS.reset);
  });

  this.updateMenu();
  if (this.dom.objectSearch.value) {
    this.applyFilterValue(this.dom.objectSearch.value);
  }
};

// Table event handler, change status
StageHelper.prototype.onTableClick = function (event) {
  var target = event.target || event.srcElement;
  if (!target) return;

  var td;
  if (target.tagName === "A") {
    td = target.parentNode;
  } else if (target.tagName === "TD") {
    td = target;
    if (td.children.length === 1 && td.children[0].tagName === "A") {
      target = td.children[0];
    } else return;
  } else return;

  if (["TD","TH"].indexOf(td.tagName) == -1 || td.className != "cmd") return;

  var status    = this.STATUS[target.innerText]; // Convert anchor text to status
  var targetRow = td.parentNode;

  if (td.tagName === "TD") {
    this.updateRow(targetRow, status);
  } else { // TH
    this.iterateStageTab(true, function (row) {
      if (row.style.display !== "none"            // Not filtered out
        && row.className === targetRow.className  // Same context as header
      ) {
        this.updateRow(row, status);
      }
    });
  }

  this.updateMenu();
};

StageHelper.prototype.onCtrlEnter = function (e) {
  if (e.ctrlKey && (e.which === 10 || e.key === "Enter")){
    var clickMap = {
      "default":  this.dom.commitAllBtn,
      "selected": this.dom.commitSelectedBtn,
      "filtered": this.dom.commitFilteredBtn
    };
    clickMap[this.calculateActiveCommitCommand()].click();
  }
};

// Search object
StageHelper.prototype.onFilter = function (e) {
  if ( // Enter hit or clear, IE SUCKS !
    e.type === "input" && !e.target.value && this.lastFilterValue
    || e.type === "keypress" && (e.which === 13 || e.key === "Enter") && !e.ctrlKey ) {

    this.applyFilterValue(e.target.value);
    submitSapeventForm({ filterValue: e.target.value }, "stage_filter", "post");
  }
};

StageHelper.prototype.applyFilterValue = function(sFilterValue) {

  this.lastFilterValue = sFilterValue;
  this.filteredCount = this.iterateStageTab(true, this.applyFilterToRow, sFilterValue);
  this.updateMenu();

};

// Apply filter to a single stage line - hide or show
StageHelper.prototype.applyFilterToRow = function (row, filter) {
  // Collect data cells
  var targets = this.filterTargets.map(function(attr) {
    var elem = row.cells[this.colIndex[attr]];
    if (elem.firstChild && elem.firstChild.tagName === "SPAN") elem = elem.firstChild;
    if (elem.firstChild && elem.firstChild.tagName === "I") elem = elem.nextChild;
    if (elem.firstChild && elem.firstChild.tagName === "A") elem = elem.firstChild;
    return {
      elem:      elem,
      plainText: elem.innerText.replace(/ /g, "\u00a0"), // without tags, with encoded spaces
      curHtml:   elem.innerHTML
    };
  }, this);

  var isVisible = false;

  // Apply filter to cells, mark filtered text
  for (var i = targets.length - 1; i >= 0; i--) {
    var target = targets[i];
    target.newHtml = (filter)
      ? target.plainText.replace(filter, "<mark>"+filter+"</mark>")
      : target.plainText;
    target.isChanged = target.newHtml !== target.curHtml;
    isVisible        = isVisible || !filter || target.newHtml !== target.plainText;
  }

  // Update DOM
  row.style.display = isVisible ? "" : "none";
  for (var j = targets.length - 1; j >= 0; j--) {
    if (targets[j].isChanged) targets[j].elem.innerHTML = targets[j].newHtml;
  }
  return isVisible ? 1 : 0;
};

// Get how status should affect object counter
StageHelper.prototype.getStatusImpact = function (status) {
  if (typeof status !== "string"
    || status.length !== 1
    || this.STATUS.isValid(status) ) {
    alert("Unknown status");
  } else {
    return (status !== this.STATUS.reset) ? 1 : 0;
  }
};

// Update table line
StageHelper.prototype.updateRow = function (row, newStatus) {
  var oldStatus = row.cells[this.colIndex["status"]].innerText;

  if (oldStatus !== newStatus) {
    this.updateRowStatus(row, newStatus);
    this.updateRowCommand(row, newStatus);
  } else if (!row.cells[this.colIndex["cmd"]].children.length) {
    this.updateRowCommand(row, newStatus); // For initial run
  }

  this.selectedCount += this.getStatusImpact(newStatus) - this.getStatusImpact(oldStatus);
};

// Update Status cell (render set of commands)
StageHelper.prototype.updateRowStatus = function (row, status) {
  row.cells[this.colIndex["status"]].innerText = status;
  if (status === this.STATUS.reset) {
    row.cells[this.colIndex["status"]].classList.remove(this.HIGHLIGHT_STYLE);
  } else {
    row.cells[this.colIndex["status"]].classList.add(this.HIGHLIGHT_STYLE);
  }
};

// Update Command cell (render set of commands)
StageHelper.prototype.updateRowCommand = function (row, status) {
  var cell = row.cells[this.colIndex["cmd"]];
  if (status === this.STATUS.reset) {
    cell.innerHTML = (row.className == "local")
      ? this.TEMPLATES.cmdLocal
      : this.TEMPLATES.cmdRemote;
  } else {
    cell.innerHTML = this.TEMPLATES.cmdReset;
  }
};

StageHelper.prototype.calculateActiveCommitCommand = function () {
  var active;
  if (this.selectedCount > 0) {
    active = "selected";
  } else if (this.lastFilterValue) {
    active = "filtered";
  } else {
    active = "default";
  }
  return active;
};

// Update menu items visibility
StageHelper.prototype.updateMenu = function () {
  var display = this.calculateActiveCommitCommand();
  if (display === "selected") this.dom.selectedCounter.innerText = this.selectedCount.toString();
  if (display === "filtered") this.dom.filteredCounter.innerText = this.filteredCount.toString();

  this.dom.commitAllBtn.style.display      = display === "default" ? "" : "none";
  this.dom.commitSelectedBtn.style.display = display === "selected" ? "" : "none";
  this.dom.commitFilteredBtn.style.display = display === "filtered" ? "" : "none";
};

// Submit stage state to the server
StageHelper.prototype.submit = function () {
  submitSapeventForm(this.collectData(), this.formAction);
};

StageHelper.prototype.submitVisible = function () {
  this.markVisiblesAsAdded();
  submitSapeventForm(this.collectData(), this.formAction);
};

StageHelper.prototype.submitPatch = function(){
  submitSapeventForm(this.collectData(), this.patchAction);
};

// Extract data from the table
StageHelper.prototype.collectData = function () {
  var data  = {};
  this.iterateStageTab(false, function (row) {
    data[row.cells[this.colIndex["name"]].innerText] = row.cells[this.colIndex["status"]].innerText;
  });
  return data;
};

StageHelper.prototype.markVisiblesAsAdded = function () {
  this.iterateStageTab(false, function (row) {
    // TODO refacotr, unify updateRow logic
    if (row.style.display === "" && row.className === "local") { // visible
      this.updateRow(row, this.STATUS.add);
    } else {
      this.updateRow(row, this.STATUS.reset);
    }
  });
};

// Table iteration helper
StageHelper.prototype.iterateStageTab = function (changeMode, cb /*, ...*/) {
  var restArgs = Array.prototype.slice.call(arguments, 2);
  var table    = this.dom.stageTab;
  var retTotal = 0;

  if (changeMode) {
    var scrollOffset = window.pageYOffset;
    this.dom.stageTab.style.display = "none";
  }

  for (var b = 0, bN = table.tBodies.length; b < bN; b++) {
    var tbody = table.tBodies[b];
    for (var r = 0, rN = tbody.rows.length; r < rN; r++) {
      var args = [tbody.rows[r]].concat(restArgs);
      var retVal = cb.apply(this, args); // callback
      if (typeof retVal === "number") retTotal += retVal;
    }
  }

  if (changeMode) {
    this.dom.stageTab.style.display = "";
    window.scrollTo(0, scrollOffset);
  }

  return retTotal;
};

/**********************************************************
 * Check list wrapper
 **********************************************************/

function CheckListWrapper(id, cbAction, cbActionOnlyMyChanges) {
  this.id         = document.getElementById(id);
  this.cbAction   = cbAction;
  this.cbActionOnlyMyChanges = cbActionOnlyMyChanges;
  this.id.onclick = this.onClick.bind(this);
}

CheckListWrapper.prototype.onClick = function(e) { // eslint-disable-line no-unused-vars
  // Get nodes
  var target = event.target || event.srcElement;
  if (!target) return;
  if (target.tagName !== "A") { target = target.parentNode } // icon clicked
  if (target.tagName !== "A") return;
  if (target.parentNode.tagName !== "LI") return;

  var nodeA    = target;
  var nodeLi   = target.parentNode;
  var nodeIcon = target.children[0];
  if (!nodeIcon.classList.contains("icon")) return;

  // Node updates
  var option   = nodeA.innerText;
  var oldState = nodeLi.getAttribute("data-check");
  if (oldState === null) return; // no data-check attribute - non-checkbox
  var newState = oldState === "X" ? false : true;

  if (newState) {
    nodeIcon.classList.remove("grey");
    nodeIcon.classList.add("blue");
    nodeLi.setAttribute("data-check", "X");
  } else {
    nodeIcon.classList.remove("blue");
    nodeIcon.classList.add("grey");
    nodeLi.setAttribute("data-check", "");
  }

  // Action callback, special handling for "Only My Changes"
  if(option === "Only my changes") {
    this.cbActionOnlyMyChanges(nodeLi.getAttribute("data-aux"), newState);

    // hide "Changed By" menu
  } else {
    this.cbAction(nodeLi.getAttribute("data-aux"), option, newState);
  }
};

/**********************************************************
 * Diff page logic
 **********************************************************/

// Diff helper constructor
function DiffHelper(params) {
  this.pageSeed    = params.seed;
  this.counter     = 0;
  this.stageAction = params.stageAction;

  // DOM nodes
  this.dom = {
    diffList:    document.getElementById(params.ids.diffList),
    stageButton: document.getElementById(params.ids.stageButton)
  };

  this.repoKey = this.dom.diffList.getAttribute("data-repo-key");
  if (!this.repoKey) return; // Unexpected

  this.dom.jump = document.getElementById(params.ids.jump);
  this.dom.jump.onclick = this.onJump.bind(this);

  // Checklist wrapper
  if (document.getElementById(params.ids.filterMenu)) {
    this.checkList = new CheckListWrapper(params.ids.filterMenu, this.onFilter.bind(this), this.onFilterOnlyMyChanges.bind(this));
    this.dom.filterButton = document.getElementById(params.ids.filterMenu).parentNode;
  }

  // Hijack stage command
  if (this.dom.stageButton) {
    this.dom.stageButton.href    = "#";
    this.dom.stageButton.onclick = this.onStage.bind(this);
  }
}

// Action on jump click
DiffHelper.prototype.onJump = function(e){
  var text = ((e.target && e.target.text) || e);
  if (!text) return;

  var elFile = document.querySelector("[data-file*='" + text + "']");
  if (!elFile) return;

  setTimeout(function(){
    elFile.scrollIntoView();
  }, 100);
};

// Action on filter click
DiffHelper.prototype.onFilter = function(attr, target, state) {
  this.applyFilter(attr, target, state);
  this.highlightButton(state);
};

DiffHelper.prototype.onFilterOnlyMyChanges = function(username, state) {
  this.applyOnlyMyChangesFilter(username, state);
  this.counter = 0;

  if(state) {
    this.dom.filterButton.classList.add("bgorange");
  } else {
    this.dom.filterButton.classList.remove("bgorange");
  }

  // apply logic on Changed By list items
  var changedByListItems = Array.prototype.slice.call(document.querySelectorAll("[data-aux*=changed-by]"));

  changedByListItems
    .map(function(item) {
      var nodeIcon = item.children[0].children[0];

      if (state === true) {
        if(item.innerText === username) { // current user
          item.style.display = "";
          item.setAttribute("data-check", "X");

          if(nodeIcon) {
            nodeIcon.classList.remove("grey");
            nodeIcon.classList.add("blue");
          }
        } else { // other users
          item.style.display = "none";
          item.setAttribute("data-check", "");
        }
      } else {
        item.style.display = "";
        item.setAttribute("data-check", "X");

        if(nodeIcon) {
          nodeIcon.classList.remove("grey");
          nodeIcon.classList.add("blue");
        }
      }
    });
};

DiffHelper.prototype.applyOnlyMyChangesFilter = function (username, state) {

  var jumpListItems = Array.prototype.slice.call(document.querySelectorAll("[id*=li_jump]"));

  this.iterateDiffList(function(div) {
    if (state === true) { // switching on "Only my changes" filter
      if (div.getAttribute("data-changed-by") === username) {
        div.style.display = state ? "" : "none";
      } else {
        div.style.display = state ? "none" : "";
      }
    } else { // disabling
      div.style.display = "";
    }

    // hide the file in the jump list
    var dataFile = div.getAttribute("data-file");
    jumpListItems
      .filter(function(item){ return dataFile.includes(item.text) })
      .map(function(item){ item.style.display = div.style.display });
  });
};

// Hide/show diff based on params
DiffHelper.prototype.applyFilter = function (attr, target, state) {

  var jumpListItems = Array.prototype.slice.call(document.querySelectorAll("[id*=li_jump]"));

  this.iterateDiffList(function(div) {
    if (div.getAttribute("data-"+attr) === target) {
      div.style.display = state ? "" : "none";

      // hide the file in the jump list
      var dataFile = div.getAttribute("data-file");
      jumpListItems
        .filter(function(item){ return dataFile.includes(item.text) })
        .map(function(item){ item.style.display = div.style.display });
    }
  });
};

// Action on stage -> save visible diffs as state for stage page
DiffHelper.prototype.onStage = function (e) { // eslint-disable-line no-unused-vars
  if (window.sessionStorage) {
    var data = this.buildStageCache();
    window.sessionStorage.setItem(this.pageSeed, JSON.stringify(data));
  }
  var getParams = {key: this.repoKey, seed: this.pageSeed};
  submitSapeventForm(getParams, this.stageAction, "get");
};

// Collect visible diffs
DiffHelper.prototype.buildStageCache = function () {
  var list = {};
  this.iterateDiffList(function(div) {
    var filename = div.getAttribute("data-file");
    if (!div.style.display && filename) { // No display override - visible !!
      list[filename] = "A"; // Add
    }
  });
  return list;
};

// Table iterator
DiffHelper.prototype.iterateDiffList = function (cb /*, ...*/) {
  var restArgs = Array.prototype.slice.call(arguments, 1);
  var diffList = this.dom.diffList;

  for (var i = 0, iN = diffList.children.length; i < iN; i++) {
    var div = diffList.children[i];
    if (div.className !== "diff") continue;
    var args = [div].concat(restArgs);
    cb.apply(this, args); // callback
  }
};

// Highlight Filter button if filter is activate
DiffHelper.prototype.highlightButton = function(state) {
  this.counter += state ? -1 : 1;
  if (this.counter > 0) {
    this.dom.filterButton.classList.add("bgorange");
  } else {
    this.dom.filterButton.classList.remove("bgorange");
  }
};

//Collapse/Expand diffs
function onDiffCollapse(event) {
  var source = event.target || event.srcElement;
  var nextDiffContent = source.parentElement.nextElementSibling;
  var hide;

  if(source.classList.contains("icon-chevron-down")){
    source.classList.remove("icon-chevron-down");
    source.classList.add("icon-chevron-right");
    hide = true;
  } else {
    source.classList.remove("icon-chevron-right");
    source.classList.add("icon-chevron-down");
    hide = false;
  }

  hide ? nextDiffContent.classList.add("nodisplay") : nextDiffContent.classList.remove("nodisplay");
}

// Add Bottom margin, so that we can scroll to the top of the last file
function addMarginBottom(){
  document.getElementsByTagName("body")[0].style.marginBottom = screen.height + "px";
}


/**********************************************************
 * Diff page logic of column selection
 **********************************************************/

function DiffColumnSelection() {
  this.selectedColumnIdx = -1;
  this.lineNumColumnIdx = -1;
  //https://stackoverflow.com/questions/2749244/javascript-setinterval-and-this-solution
  document.addEventListener("mousedown", this.mousedownEventListener.bind(this));
  document.addEventListener("copy", this.copyEventListener.bind(this));
}

DiffColumnSelection.prototype.mousedownEventListener = function(e) {
  // Select text in a column of an HTML table and copy to clipboard (in DIFF view)
  // (https://stackoverflow.com/questions/6619805/select-text-in-a-column-of-an-html-table)
  // Process mousedown event for all TD elements -> apply CSS class at TABLE level.
  // (https://stackoverflow.com/questions/40956717/how-to-addeventlistener-to-multiple-elements-in-a-single-line)
  var unifiedLineNumColumnIdx = 0;
  var unifiedCodeColumnIdx = 3;
  var splitLineNumLeftColumnIdx = 0;
  var splitCodeLeftColumnIdx = 2;
  var splitLineNumRightColumnIdx = 3;
  var splitCodeRightColumnIdx = 5;

  if (e.button !== 0) return; // function is only valid for left button, not right button

  var td = e.target;
  while (td != undefined && td.tagName != "TD" && td.tagName != "TBODY") td = td.parentElement;
  if (td == undefined) return;
  var table = td.parentElement.parentElement;

  var patchColumnCount = 0;
  if (td.parentElement.cells[0].classList.contains("patch")) {
    patchColumnCount = 1;
  }

  if (td.classList.contains("diff_left")) {
    table.classList.remove("diff_select_right");
    table.classList.add("diff_select_left");
    if ( window.getSelection() && this.selectedColumnIdx != splitCodeLeftColumnIdx + patchColumnCount ) {
      // De-select to avoid effect of dragging selection in case the right column was first selected
      if (document.body.createTextRange) { // All IE but Edge
        // document.getSelection().removeAllRanges() may trigger error
        // so use this code which is equivalent but does not fail
        // (https://stackoverflow.com/questions/22914075/javascript-error-800a025e-using-range-selector)
        range = document.body.createTextRange();
        range.collapse();
        range.select();
      } else {
        document.getSelection().removeAllRanges();
      }}
    this.selectedColumnIdx = splitCodeLeftColumnIdx + patchColumnCount;
    this.lineNumColumnIdx = splitLineNumLeftColumnIdx + patchColumnCount;

  } else if (td.classList.contains("diff_right")) {
    table.classList.remove("diff_select_left");
    table.classList.add("diff_select_right");
    if ( window.getSelection() && this.selectedColumnIdx != splitCodeRightColumnIdx + patchColumnCount ) {
      if (document.body.createTextRange) { // All IE but Edge
        // document.getSelection().removeAllRanges() may trigger error
        // so use this code which is equivalent but does not fail
        // (https://stackoverflow.com/questions/22914075/javascript-error-800a025e-using-range-selector)
        var range = document.body.createTextRange();
        range.collapse();
        range.select();
      } else {
        document.getSelection().removeAllRanges();
      }}
    this.selectedColumnIdx = splitCodeRightColumnIdx + patchColumnCount;
    this.lineNumColumnIdx = splitLineNumRightColumnIdx + patchColumnCount;

  } else if (td.classList.contains("diff_unified")) {
    this.selectedColumnIdx = unifiedCodeColumnIdx;
    this.lineNumColumnIdx = unifiedLineNumColumnIdx;

  } else {
    this.selectedColumnIdx = -1;
    this.lineNumColumnIdx = -1;
  }
};

DiffColumnSelection.prototype.copyEventListener = function(e) {
  // Select text in a column of an HTML table and copy to clipboard (in DIFF view)
  // (https://stackoverflow.com/questions/6619805/select-text-in-a-column-of-an-html-table)
  var td = e.target;
  while (td != undefined && td.tagName != "TD" && td.tagName != "TBODY") td = td.parentElement;
  if(td != undefined){
    // Use window.clipboardData instead of e.clipboardData
    // (https://stackoverflow.com/questions/23470958/ie-10-copy-paste-issue)
    var clipboardData = ( e.clipboardData == undefined ? window.clipboardData : e.clipboardData );
    var text = this.getSelectedText();
    clipboardData.setData("text", text);
    e.preventDefault();
  }
};

DiffColumnSelection.prototype.getSelectedText = function() {
  // Select text in a column of an HTML table and copy to clipboard (in DIFF view)
  // (https://stackoverflow.com/questions/6619805/select-text-in-a-column-of-an-html-table)
  var sel = window.getSelection(),
    range = sel.getRangeAt(0),
    doc = range.cloneContents(),
    nodes = doc.querySelectorAll("tr"),
    text = "";
  if (nodes.length === 0) {
    text = doc.textContent;
  } else {
    var newline = "",
      realThis = this;
    [].forEach.call(nodes, function(tr, i) {
      var cellIdx = ( i==0 ? 0 : realThis.selectedColumnIdx );
      if (tr.cells.length > cellIdx) {
        var tdSelected = tr.cells[cellIdx];
        var tdLineNum = tr.cells[realThis.lineNumColumnIdx];
        // copy is interesting for remote code, don't copy lines which exist only locally
        if (i==0 || tdLineNum.getAttribute("line-num")!="") {
          text += newline + tdSelected.textContent;
          // special processing for TD tag which sometimes contains newline
          // (expl: /src/ui/zabapgit_js_common.w3mi.data.js) so don't add newline again in that case.
          var lastChar = tdSelected.textContent[ tdSelected.textContent.length - 1 ];
          if ( lastChar == "\n" ) newline = "";
          else newline = "\n";
        }}});}
  return text;
};

/**********************************************************
 * Other functions
 **********************************************************/

// News announcement
function toggleDisplay(divId) {
  var div = document.getElementById(divId);
  if (div) div.style.display = (div.style.display) ? "" : "none";
}

function KeyNavigation() { }

KeyNavigation.prototype.onkeydown = function(event) {
  if (event.defaultPrevented) return;

  // navigate with arrows through list items and support pressing links with enter and space
  var isHandled = false;
  if (event.key === "Enter" || event.key === "") {
    isHandled = this.onEnterOrSpace();
  } else if (/Down$/.test(event.key)) {
    isHandled = this.onArrowDown();
  } else if (/Up$/.test(event.key)) {
    isHandled = this.onArrowUp();
  } else if (event.key === "Backspace") {
    isHandled = this.onBackspace();
  }

  if (isHandled) event.preventDefault();
};

KeyNavigation.prototype.onEnterOrSpace = function () {
  if (document.activeElement.nodeName !== "A") return;
  var anchor = document.activeElement;

  if (anchor.href.replace(/#$/, "") === document.location.href.replace(/#$/, "")
    && !anchor.onclick
    && anchor.parentElement
    && anchor.parentElement.nodeName === "LI" ) {
    anchor.parentElement.classList.toggle("force-nav-hover");
  } else {
    anchor.click();
  }
  return true;
};

KeyNavigation.prototype.focusListItem = function (li) {
  var anchor = li.firstElementChild;
  if (!anchor || anchor.nodeName !== "A") return false;
  anchor.focus();
  return true;
};

KeyNavigation.prototype.closeDropdown = function (dropdownLi) {
  dropdownLi.classList.remove("force-nav-hover");
  if (dropdownLi.firstElementChild.nodeName === "A") dropdownLi.firstElementChild.focus();
  return true;
};

KeyNavigation.prototype.onBackspace = function () {
  var activeElement = document.activeElement;

  // Detect opened subsequent dropdown
  if (activeElement.nodeName === "A"
    && activeElement.parentElement
    && activeElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.classList.contains("force-nav-hover")) {
    return this.closeDropdown(activeElement.parentElement);
  }

  // Detect opened parent dropdown
  if (activeElement.nodeName === "A"
    && activeElement.parentElement
    && activeElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.parentElement
    && activeElement.parentElement.parentElement.nodeName === "UL"
    && activeElement.parentElement.parentElement.parentElement
    && activeElement.parentElement.parentElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.parentElement.parentElement.classList.contains("force-nav-hover")) {
    return this.closeDropdown(activeElement.parentElement.parentElement.parentElement);
  }
};

KeyNavigation.prototype.onArrowDown = function () {
  var activeElement = document.activeElement;

  // Start of dropdown list: LI > selected A :: UL > LI > A
  if (activeElement.nodeName === "A"
    && activeElement.parentElement
    && activeElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.classList.contains("force-nav-hover") // opened dropdown
    && activeElement.nextElementSibling
    && activeElement.nextElementSibling.nodeName === "UL"
    && activeElement.nextElementSibling.firstElementChild
    && activeElement.nextElementSibling.firstElementChild.nodeName === "LI") {
    return this.focusListItem(activeElement.nextElementSibling.firstElementChild);
  }

  // Next item of dropdown list: ( LI > selected A ) :: LI > A
  if (activeElement.nodeName === "A"
    && activeElement.parentElement
    && activeElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.nextElementSibling
    && activeElement.parentElement.nextElementSibling.nodeName === "LI") {
    return this.focusListItem(activeElement.parentElement.nextElementSibling);
  }
};

KeyNavigation.prototype.onArrowUp = function () {
  var activeElement = document.activeElement;

  // Prev item of dropdown list: ( LI > selected A ) <:: LI > A
  if (activeElement.nodeName === "A"
    && activeElement.parentElement
    && activeElement.parentElement.nodeName === "LI"
    && activeElement.parentElement.previousElementSibling
    && activeElement.parentElement.previousElementSibling.nodeName === "LI") {
    return this.focusListItem(activeElement.parentElement.previousElementSibling);
  }
};

KeyNavigation.prototype.getHandler = function () {
  return this.onkeydown.bind(this);
};

// this functions enables the navigation with arrows through list items (li)
// e.g. in dropdown menus
function enableArrowListNavigation() {
  document.addEventListener("keydown", new KeyNavigation().getHandler());
}

/* LINK HINTS - Vimium like link hints */

function LinkHints(linkHintHotKey){
  this.linkHintHotKey    = linkHintHotKey;
  this.areHintsDisplayed = false;
  this.pendingPath       = ""; // already typed code prefix
  this.hintsMap          = this.deployHintContainers();
  this.activatedDropdown = null;
}

LinkHints.prototype.getHintStartValue = function(targetsCount){
  // e.g. if we have 89 tooltips we start from 10
  //      if we have 90 tooltips we start from 100
  //      if we have 900 tooltips we start from 1000
  var
    baseLength = Math.pow(10, targetsCount.toString().length - 1),
    maxHintStringLength = (targetsCount + baseLength).toString().length;
  return Math.pow(10, maxHintStringLength - 1);
};

LinkHints.prototype.deployHintContainers = function() {

  var hintTargets = document.querySelectorAll("a, input, textarea");
  var codeCounter = this.getHintStartValue(hintTargets.length);
  var hintsMap    = { first: codeCounter };

  // <span class="link-hint" data-code="123">
  //   <span class="pending">12</span><span>3</span>
  // </span>
  for (var i = 0, N = hintTargets.length; i < N; i++) {
    var hint = {};
    hint.container     = document.createElement("span");
    hint.pendingSpan   = document.createElement("span");
    hint.remainingSpan = document.createElement("span");
    hint.parent        = hintTargets[i];
    hint.code          = codeCounter.toString();

    hint.container.appendChild(hint.pendingSpan);
    hint.container.appendChild(hint.remainingSpan);

    hint.pendingSpan.classList.add("pending");
    hint.container.classList.add("link-hint");
    if (hint.parent.nodeName === "INPUT" || hint.parent.nodeName === "TEXTAREA"){
      hint.container.classList.add("link-hint-input");
    } else {
      hint.container.classList.add("link-hint-a");
    }

    hint.container.classList.add("nodisplay");            // hide by default
    hint.container.dataset.code = codeCounter.toString(); // not really needed, more for debug

    if (hintTargets[i].nodeName === "INPUT" || hintTargets[i].nodeName === "TEXTAREA") {
      // does not work if inside the input, so appending right after
      hintTargets[i].insertAdjacentElement("afterend", hint.container);
    } else {
      hintTargets[i].appendChild(hint.container);
    }
    hintsMap[codeCounter++] = hint;
  }

  hintsMap.last = codeCounter - 1;
  return hintsMap;
};

LinkHints.prototype.getHandler = function() {
  return this.handleKey.bind(this);
};

LinkHints.prototype.handleKey = function(event){

  if (event.defaultPrevented) {
    return;
  }

  var activeElement = (document.activeElement && document.activeElement) || {};

  // link hints are disabled for input and textareas for obvious reasons.
  // Maybe we must add other types here in the future
  if (event.key === this.linkHintHotKey && activeElement.type !== "text" && activeElement.type !== "number" && activeElement.nodeName !== "TEXTAREA") {

    // on user hide hints, close an opened dropdown too
    if (this.areHintsDisplayed && this.activatedDropdown) this.closeActivatedDropdown();

    this.pendingPath = "";
    this.displayHints(!this.areHintsDisplayed);

  } else if (this.areHintsDisplayed) {

    // the user tries to reach a hint
    this.pendingPath += event.key;
    var hint = this.hintsMap[this.pendingPath];

    if (hint) { // we are there, we have a fully specified tooltip. Let's activate it
      this.displayHints(false);
      event.preventDefault();
      this.hintActivate(hint);
    } else {
      // we are not there yet, but let's filter the link so that only
      // the partially matched are shown
      var visibleHints = this.filterHints();
      if (!visibleHints) {
        this.displayHints(false);
        if (this.activatedDropdown) this.closeActivatedDropdown();
      }
    }
  }
};

LinkHints.prototype.closeActivatedDropdown = function() {
  if (!this.activatedDropdown) return;
  this.activatedDropdown.classList.remove("force-nav-hover");
  this.activatedDropdown = null;
};

LinkHints.prototype.displayHints = function(isActivate) {
  this.areHintsDisplayed = isActivate;
  for (var i = this.hintsMap.first; i <= this.hintsMap.last; i++) {
    var hint = this.hintsMap[i];
    if (isActivate) {
      hint.container.classList.remove("nodisplay");
      hint.pendingSpan.innerText   = "";
      hint.remainingSpan.innerText = hint.code;
    } else {
      hint.container.classList.add("nodisplay");
    }
  }
};

LinkHints.prototype.hintActivate = function (hint) {
  if (hint.parent.nodeName === "A"
    // hint.parent.href doesn't have a # at the end while accessing dropdowns the first time.
    // Seems like a idiosyncrasy of SAPGUI's IE. So let's ignore the last character.
    && ( hint.parent.href.substr(0, hint.parent.href.length - 1) === document.location.href ) // href is #
    && !hint.parent.onclick                         // no handler
    && hint.parent.parentElement && hint.parent.parentElement.nodeName === "LI") {
    // probably it is a dropdown ...
    this.activatedDropdown = hint.parent.parentElement;
    this.activatedDropdown.classList.toggle("force-nav-hover");
    hint.parent.focus();
  } else if (hint.parent.type === "checkbox") {
    this.toggleCheckbox(hint);
  } else if (hint.parent.type === "submit") {
    hint.parent.click();
  } else if (hint.parent.nodeName === "INPUT" || hint.parent.nodeName === "TEXTAREA") {
    hint.parent.focus();
  } else {
    hint.parent.click();
    if (this.activatedDropdown) this.closeActivatedDropdown();
  }
};

LinkHints.prototype.toggleCheckbox = function (hint) {
  // ensures that onclick handler is executed
  // https://stackoverflow.com/questions/41981509/trigger-an-event-when-a-checkbox-is-changed-programmatically-via-javascript
  var event = document.createEvent("HTMLEvents");
  var checked = hint.parent.checked;
  event.initEvent("click", false, true);
  hint.parent.parentElement.dispatchEvent(event);
  if (checked === hint.parent.checked) {
    // fallback if no handler is registered
    hint.parent.checked = !hint.parent.checked;
  }
};

LinkHints.prototype.filterHints = function () {
  var visibleHints = 0;
  for (var i = this.hintsMap.first; i <= this.hintsMap.last; i++) {
    var hint = this.hintsMap[i];
    if (i.toString().startsWith(this.pendingPath)) {
      hint.pendingSpan.innerText   = this.pendingPath;
      hint.remainingSpan.innerText = hint.code.substring(this.pendingPath.length);
      // hint.container.classList.remove("nodisplay"); // for backspace
      visibleHints++;
    } else {
      hint.container.classList.add("nodisplay");
    }
  }
  return visibleHints;
};

function activateLinkHints(linkHintHotKey) {
  if (!linkHintHotKey) return;
  var oLinkHint = new LinkHints(linkHintHotKey);
  document.addEventListener("keypress", oLinkHint.getHandler());
}

/* HOTKEYS */

function Hotkeys(oKeyMap){

  this.oKeyMap = oKeyMap || {};

  // these are the hotkeys provided by the backend
  Object.keys(this.oKeyMap).forEach(function(sKey){

    var action = this.oKeyMap[sKey];

    // add a tooltip/title with the hotkey, currently only sapevents are supported
    this.getAllSapEventsForSapEventName(action).forEach(function(elAnchor) {
      elAnchor.title = elAnchor.title + " [" + sKey + "]";
    });

    // We replace the actions with callback functions to unify
    // the hotkey execution
    this.oKeyMap[sKey] = function(oEvent) {

      // gHelper is only valid for diff page
      var diffHelper = (window.gHelper || {});

      // We have either a js function on this
      if (this[action]) {
        this[action].call(this);
        return;
      }

      // Or a method of the helper object for the diff page
      if (diffHelper[action]){
        diffHelper[action].call(diffHelper);
        return;
      }

      // Or a global function
      if (window[action]) {
        window[action].call(this);
        return;
      }

      // Or a SAP event
      var sUiSapEventHref = this.getSapEventHref(action);
      if (sUiSapEventHref) {
        submitSapeventForm({}, sUiSapEventHref, "post");
        oEvent.preventDefault();
        return;
      }

    };

  }.bind(this));

}

Hotkeys.prototype.showHotkeys = function() {
  var elHotkeys = document.querySelector("#hotkeys");

  if (elHotkeys) {
    elHotkeys.style.display = (elHotkeys.style.display) ? "" : "none";
  }
};

Hotkeys.prototype.getAllSapEventsForSapEventName = function(sSapEvent) {
  return [].slice.call(document.querySelectorAll('a[href*="sapevent:' + sSapEvent + '"], a[href*="SAPEVENT:' + sSapEvent + '"]'));
};

Hotkeys.prototype.getSapEventHref = function(sSapEvent) {

  return this.getAllSapEventsForSapEventName(sSapEvent)
    .map(function(oSapEvent){
      return oSapEvent.href;
    })
    .filter(function(sapEventHref){
      // eliminate false positives
      return sapEventHref.match(new RegExp("\\b" + sSapEvent + "\\b"));
    })
    .pop();

};

Hotkeys.prototype.onkeydown = function(oEvent){

  if (oEvent.defaultPrevented) {
    return;
  }

  var activeElementType = ((document.activeElement && document.activeElement.nodeName) || "");

  if (activeElementType === "INPUT" || activeElementType === "TEXTAREA") {
    return;
  }

  var
    sKey = oEvent.key || String.fromCharCode(oEvent.keyCode),
    fnHotkey = this.oKeyMap[sKey];

  if (fnHotkey) {
    fnHotkey.call(this, oEvent);
  }
};

Hotkeys.addHotkeyToHelpSheet = function(key, description) {
  var hotkeysUl = document.querySelector("#hotkeys ul.hotkeys");
  if (!hotkeysUl) return;

  var li              = document.createElement("li");
  var spanId          = document.createElement("span");
  spanId.className    = "key-id";
  spanId.innerText    = key;
  var spanDescr       = document.createElement("span");
  spanDescr.className = "key-descr";
  spanDescr.innerText = description;
  li.appendChild(spanId);
  li.appendChild(spanDescr);

  hotkeysUl.appendChild(li);
};

function setKeyBindings(oKeyMap){

  var oHotkeys = new Hotkeys(oKeyMap);

  document.addEventListener("keypress", oHotkeys.onkeydown.bind(oHotkeys));
  setTimeout(function(){
    var div = document.getElementById("hotkeys-hint");
    if (div) div.style.opacity = 0.2;
  }, 4900);
  setTimeout(function(){ toggleDisplay("hotkeys-hint") }, 5000);
}

/*
  Patch / git add -p
  */

/*
  We have three type of cascading checkboxes.
  Which means that by clicking a file or section checkbox all corresponding line checkboxes are checked.

  The id of the checkbox indicates its semantics and its membership.

  */

/*
  1) file links

      example id of file link

      patch_file_zcl_abapgit_user_exit.clas.abap
      \________/ \_____________________________/
          |                   |
          |                   |____ file name
          |
          |
          |
      constant prefix

  */

function PatchFile(sId){
  var oRegex = new RegExp("(" + this.ID + ")_(.*$)");
  var oMatch = sId.match(oRegex);
  this.id        = sId;
  this.prefix    = oMatch[1];
  this.file_name = oMatch[2];
}

PatchFile.prototype.ID = "patch_file";

/*
  2) section links within a file

      example id of section link

      patch_section_zcl_abapgit_user_exit.clas.abap_1
      \___________/ \_____________________________/ ^
            |                   |                   |
            |               file name               |
            |                                       |
            |                                       ------ section
            |
      constant prefix

    */

function PatchSection(sId){
  var oRegex = new RegExp("(" + this.ID + ")_(.*)_(\\d+$)");
  var oMatch = sId.match(oRegex);
  this.id        = sId;
  this.prefix    = oMatch[1];
  this.file_name = oMatch[2];
  this.section   = oMatch[3];
}

PatchSection.prototype.ID = "patch_section";

/*
  3) line links within a section

      example id of line link

      patch_line_zcl_abapgit_user_exit.clas.abap_1_25
      \________/ \_____________________________/ ^  ^
            ^                  ^                 |  |
            |                  |                 |  ------- line number
            |               file name            |
            |                                 section
            |
            |
      constant prefix

  */
function PatchLine(){
}

PatchLine.prototype.ID = "patch_line";

function Patch() { }

Patch.prototype.ID = {
  STAGE: "stage"
};

Patch.prototype.ACTION = {
  PATCH_STAGE: "patch_stage",
  PATCH_REFRESH_LOCAL: "patch_refresh_local"
};

Patch.prototype.escape = function(sFileName){
  return sFileName
    .replace(/\./g, "\\.")
    .replace(/#/g, "\\#");
};

Patch.prototype.preparePatch = function(){

  this.registerClickHandlerForFiles();
  this.registerClickHandlerForSections();
  this.registerClickHandlerForLines();

};

Patch.prototype.buildSelectorInputStartsWithId = function(sId){
  return "input[id^='" + sId + "']";
};

Patch.prototype.registerClickHandlerForFiles = function(){
  this.registerClickHandlerForSelectorParent(this.buildSelectorInputStartsWithId(PatchFile.prototype.ID), this.onClickFileCheckbox);
};

Patch.prototype.registerClickHandlerForSections = function(){
  this.registerClickHandlerForSelectorParent(this.buildSelectorInputStartsWithId(PatchSection.prototype.ID), this.onClickSectionCheckbox);
};

Patch.prototype.registerClickHandlerForLines = function(){
  this.registerClickHandlerForSelectorParent(this.buildSelectorInputStartsWithId(PatchLine.prototype.ID), this.onClickLineCheckbox);
};

Patch.prototype.registerClickHandlerForSelectorParent = function(sSelector, fnCallback){

  var elAll = document.querySelectorAll(sSelector);

  [].forEach.call(elAll, function(elem){
    elem.parentElement.addEventListener("click", fnCallback.bind(this));
  }.bind(this));

};

Patch.prototype.getAllLineCheckboxesForFile = function(oFile){
  return this.getAllLineCheckboxesForId(oFile.id, PatchFile.prototype.ID);
};

Patch.prototype.getAllSectionCheckboxesForFile = function(oFile){
  return this.getAllSectionCheckboxesForId(oFile.id, PatchFile.prototype.ID);
};

Patch.prototype.getAllLineCheckboxesForSection = function(oSection){
  return this.getAllLineCheckboxesForId(oSection.id, PatchSection.prototype.ID);
};

Patch.prototype.getAllLineCheckboxesForId = function(sId, sIdPrefix){
  return this.getAllCheckboxesForId(sId, sIdPrefix,PatchLine.prototype.ID);
};

Patch.prototype.getAllSectionCheckboxesForId = function(sId, sIdPrefix){
  return this.getAllCheckboxesForId(sId, sIdPrefix, PatchSection.prototype.ID);
};

Patch.prototype.getAllCheckboxesForId = function(sId, sIdPrefix, sNewIdPrefix){
  var oRegex = new RegExp("^" + sIdPrefix);
  sId = sId.replace(oRegex, sNewIdPrefix);
  return document.querySelectorAll(this.buildSelectorInputStartsWithId(this.escape(sId)));
};

Patch.prototype.getToggledCheckbox = function(oEvent){

  var elCheckbox = null;

  // We have either an input element or any element with input child
  // in the latter case we have to toggle the checkbox manually
  if (oEvent.srcElement.nodeName === "INPUT"){
    elCheckbox = oEvent.srcElement;
  } else {
    elCheckbox = this.toggleCheckbox(oEvent.srcElement.querySelector("INPUT"));
  }

  return elCheckbox;
};

Patch.prototype.toggleCheckbox = function(elCheckbox) {
  elCheckbox.checked = !elCheckbox.checked;
  return elCheckbox;
};

Patch.prototype.onClickFileCheckbox = function(oEvent) {

  var elCheckbox = this.getToggledCheckbox(oEvent);
  var oFile = new PatchFile(elCheckbox.id);
  var elAllLineCheckboxesOfFile = this.getAllLineCheckboxesForFile(oFile);
  var elAllSectionCheckboxesOfFile = this.getAllSectionCheckboxesForFile(oFile);

  [].forEach.call(elAllLineCheckboxesOfFile,function(elem){
    elem.checked = elCheckbox.checked;
  }.bind(this));

  [].forEach.call(elAllSectionCheckboxesOfFile,function(elem){
    elem.checked = elCheckbox.checked;
  }.bind(this));

};

Patch.prototype.onClickSectionCheckbox = function(oEvent){
  var elSrcElement = this.getToggledCheckbox(oEvent);
  var oSection = new PatchSection(elSrcElement.id);
  this.clickAllLineCheckboxesInSection(oSection, elSrcElement.checked);
};

Patch.prototype.onClickLineCheckbox = function(oEvent){
  this.getToggledCheckbox(oEvent);
};

Patch.prototype.clickAllLineCheckboxesInSection = function(oSection, bChecked){

  var elAllLineCheckboxesOfSection = this.getAllLineCheckboxesForSection(oSection);

  [].forEach.call(elAllLineCheckboxesOfSection,function(elem){
    elem.checked = bChecked;
  }.bind(this));

};

Patch.prototype.registerStagePatch = function registerStagePatch(){

  var elStage = document.querySelector("#" + this.ID.STAGE);
  elStage.addEventListener("click", this.submitPatch.bind(this, this.ACTION.PATCH_STAGE));

  var aRefresh = document.querySelectorAll("[id*=patch_refresh]");
  [].forEach.call( aRefresh, function(el) {
    el.addEventListener("click", memoizeScrollPosition(this.submitPatch.bind(this, el.id)).bind(this));
  }.bind(this));

  // for hotkeys
  window.stagePatch = function(){
    this.submitPatch(this.ACTION.PATCH_STAGE);
  }.bind(this);

  window.refreshLocal = memoizeScrollPosition(function(){
    this.submitPatch(this.ACTION.PATCH_REFRESH_LOCAL);
  }.bind(this));

};

Patch.prototype.submitPatch = function(action) {
  // Collect add and remove info and submit to backend

  var aAddPatch = this.collectElementsForCheckboxId( PatchLine.prototype.ID, true);
  var aRemovePatch = this.collectElementsForCheckboxId( PatchLine.prototype.ID, false);

  submitSapeventForm({ add: aAddPatch, remove: aRemovePatch }, action, "post");
};

Patch.prototype.collectElementsForCheckboxId = function(sId, bChecked){

  var sSelector = this.buildSelectorInputStartsWithId(sId);

  return [].slice.call(document.querySelectorAll(sSelector))
    .filter(function(elem){
      return (elem.checked === bChecked);
    }).map(function(elem){
      return elem.id;
    });

};

function preparePatch(){
  var oPatch = new Patch();
  oPatch.preparePatch();
}

function registerStagePatch(){
  var oPatch = new Patch();
  oPatch.registerStagePatch();
}

/**********************************************************
 * Page branch overview
 *
 * Hovering a commit node in the branch overview will show
 * a popup with the commit details. Single click on a node
 * will fix the popup, so that users can select text. The
 * fixation is removed when any node is hovered or the popup
 * is closed via 'X'.
 *
 **********************************************************/

function BranchOverview() {
  this.bFixed = false;
  this.elCurrentCommit = {
    style : {
      display: "none"
    }
  };
}

BranchOverview.prototype.toggleCommit = function(sSha1, bFixPopup) {

  // If the popup is fixed, we just remove the fixation.
  // The popup will then be hidden by the next call of hideCommit
  if (this.bFixed) {
    this.bFixed = false;
    return;
  }

  // We hide the previous shown commit popup
  this.elCurrentCommit.style.display = "none";

  // Display the new commit popup if sha1 is supplied
  if (sSha1){
    this.elCurrentCommit = document.getElementById(sSha1);
    this.elCurrentCommit.style.display = "";

    // and fix the popup so that the next hideCommit won't hide it.
    this.bFixed = bFixPopup;

  }

};

// called by onClick of commit nodes in branch overview
BranchOverview.prototype.onCommitClick = function(commit){
  this.toggleCommit(commit.sha1, true);
};

// Called by commit:mouseover
BranchOverview.prototype.showCommit = function(event){
  this.toggleCommit(event.data.sha1);
};

// Called by commit:mouseout
BranchOverview.prototype.hideCommit = function (){
  this.toggleCommit();
};

// Initialize Top Horizontal Scroller on GitGraph
function setGitGraphScroller(){ // eslint-disable-line no-unused-vars

  // Get gitGraph Element Canvas Width
  var gitGraphEl = document.getElementById("gitGraph");
  var gitGraphWidth = gitGraphEl.offsetWidth;

  // Initialize gitGraph-HTopScroller Element width as gitGraph
  var HTopScrollerEl = document.querySelector(".gitGraph-HTopScroller");
  HTopScrollerEl.style.width = gitGraphWidth + "px";

}

// Setup Top Horizontal Scroller on GitGraph event
function GitGraphScroller() { // eslint-disable-line no-unused-vars
  var gitGraphWrapperEl = document.querySelector(".gitGraph-Wrapper");
  var gitGraphscrollWrapperEl = document.querySelector(".gitGraph-scrollWrapper");
  gitGraphWrapperEl.scrollLeft = gitGraphscrollWrapperEl.scrollLeft;
}

/**********************************************************
 * Ctrl + P - command palette
 **********************************************************/

// fuzzy match helper
// return non empty marked string in case it fits the filter
// abc + b = a<mark>b</mark>c
function fuzzyMatchAndMark(str, filter){
  var markedStr   = "";
  var filterLower = filter.toLowerCase();
  var strLower    = str.toLowerCase();
  var cur         = 0;

  for (var i = 0; i < filter.length; i++) {
    while (filterLower[i] !== strLower[cur] && cur < str.length) {
      markedStr += str[cur++];
    }
    if (cur === str.length) break;
    markedStr += "<mark>" + str[cur++] + "</mark>";
  }

  var matched = i === filter.length;
  if (matched && cur < str.length) markedStr += str.substring(cur);
  return matched ? markedStr : null;
}

function CommandPalette(commandEnumerator, opts) {
  if (typeof commandEnumerator !== "function") throw Error("commandEnumerator must be a function");
  if (typeof opts !== "object") throw Error("opts must be an object");
  if (typeof opts.toggleKey !== "string" || !opts.toggleKey) throw Error("toggleKey must be a string");
  this.commands = commandEnumerator();
  if (!this.commands) return;
  // this.commands = [{
  //   action:    "sap_event_action_code_with_params"
  //   iconClass: "icon icon_x ..."
  //   title:     "my command X"
  // }, ...];

  if (opts.toggleKey[0] === "^") {
    this.toggleKeyCtrl = true;
    this.toggleKey     = opts.toggleKey.substring(1);
    if (!this.toggleKey) throw Error("Incorrect toggleKey");
  } else {
    this.toggleKeyCtrl = false;
    this.toggleKey     = opts.toggleKey;
  }

  this.hotkeyDescription = opts.hotkeyDescription;
  this.elements = {
    palette: null,
    ul:      null,
    input:   null
  };
  this.selectIndex       = -1; // not selected
  this.filter            = "";
  this.renderAndBindElements();
  this.hookEvents();
  Hotkeys.addHotkeyToHelpSheet(opts.toggleKey, opts.hotkeyDescription);
}

CommandPalette.prototype.hookEvents = function(){
  document.addEventListener("keydown", this.handleToggleKey.bind(this));
  this.elements.input.addEventListener("keyup", this.handleInputKey.bind(this));
  this.elements.ul.addEventListener("click", this.handleUlClick.bind(this));
};

CommandPalette.prototype.renderCommandItem = function(cmd){
  var li = document.createElement("li");
  if (cmd.iconClass) {
    var icon       = document.createElement("i");
    icon.className = cmd.iconClass;
    li.appendChild(icon);
  }
  var titleSpan = document.createElement("span");
  li.appendChild(titleSpan);
  cmd.element   = li;
  cmd.titleSpan = titleSpan;
  return li;
};

CommandPalette.prototype.renderAndBindElements = function(){
  var div           = document.createElement("div");
  div.className     = "cmd-palette";
  div.style.display = "none";
  var input         = document.createElement("input");
  input.placeholder = this.hotkeyDescription;
  var ul            = document.createElement("ul");
  for (var i = 0; i < this.commands.length; i++) ul.appendChild(this.renderCommandItem(this.commands[i]));
  div.appendChild(input);
  div.appendChild(ul);

  this.elements.palette = div;
  this.elements.input   = input;
  this.elements.ul      = ul;
  document.body.appendChild(div);
};

CommandPalette.prototype.handleToggleKey = function(event){
  if (event.key !== this.toggleKey) return;
  if (this.toggleKeyCtrl && !event.ctrlKey) return;
  this.toggleDisplay();
  event.preventDefault();
};

CommandPalette.prototype.handleInputKey = function(event){
  if (event.key === "ArrowUp" || event.key === "Up") {
    this.selectPrev();
  } else if (event.key === "ArrowDown" || event.key === "Down") {
    this.selectNext();
  } else if (event.key === "Enter") {
    this.exec(this.getSelected());
  } else if (event.key === "Backspace" && !this.filter) {
    this.toggleDisplay(false);
  } else if (this.filter !== this.elements.input.value) {
    this.filter = this.elements.input.value;
    this.applyFilter();
    this.selectFirst();
  }
  event.preventDefault();
};

CommandPalette.prototype.applyFilter = function(){
  for (var i = 0; i < this.commands.length; i++) {
    var cmd = this.commands[i];
    if (!this.filter) {
      cmd.element.style.display = "";
      cmd.titleSpan.innerText   = cmd.title;
    } else {
      var matchedTitle = fuzzyMatchAndMark(cmd.title, this.filter);
      if (matchedTitle) {
        cmd.titleSpan.innerHTML   = matchedTitle;
        cmd.element.style.display = "";
      } else {
        cmd.element.style.display = "none";
      }
    }
  }
};

CommandPalette.prototype.applySelectIndex = function(newIndex){
  if (newIndex !== this.selectIndex) {
    if (this.selectIndex >= 0) this.commands[this.selectIndex].element.classList.remove("selected");
    var newCmd = this.commands[newIndex];
    newCmd.element.classList.add("selected");
    this.selectIndex = newIndex;
    this.adjustScrollPosition(newCmd.element);
  }
};

CommandPalette.prototype.selectFirst = function(){
  for (var i = 0; i < this.commands.length; i++) {
    if (this.commands[i].element.style.display === "none") continue; // skip hidden
    this.applySelectIndex(i);
    break;
  }
};

CommandPalette.prototype.selectNext = function(){
  for (var i = this.selectIndex + 1; i < this.commands.length; i++) {
    if (this.commands[i].element.style.display === "none") continue; // skip hidden
    this.applySelectIndex(i);
    break;
  }
};

CommandPalette.prototype.selectPrev = function(){
  for (var i = this.selectIndex - 1; i >= 0; i--) {
    if (this.commands[i].element.style.display === "none") continue; // skip hidden
    this.applySelectIndex(i);
    break;
  }
};

CommandPalette.prototype.getSelected = function(){
  return this.commands[this.selectIndex];
};

CommandPalette.prototype.adjustScrollPosition = function(itemElement){
  var bItem         = itemElement.getBoundingClientRect();
  var bContainer    = this.elements.ul.getBoundingClientRect();
  bItem.top         = Math.round(bItem.top);
  bItem.bottom      = Math.round(bItem.bottom);
  bItem.height      = Math.round(bItem.height);
  bItem.mid         = Math.round(bItem.top + bItem.height / 2);
  bContainer.top    = Math.round(bContainer.top);
  bContainer.bottom = Math.round(bContainer.bottom);

  if ( bItem.mid > bContainer.bottom - 2 ) {
    this.elements.ul.scrollTop += bItem.bottom - bContainer.bottom;
  } else if ( bItem.mid < bContainer.top + 2 ) {
    this.elements.ul.scrollTop += bItem.top - bContainer.top;
  }
};

CommandPalette.prototype.toggleDisplay = function(forceState) {
  var isDisplayed = (this.elements.palette.style.display !== "none");
  var tobeDisplayed = (forceState !== undefined) ? forceState : !isDisplayed;
  this.elements.palette.style.display = tobeDisplayed ? "" : "none";
  if (tobeDisplayed) {
    this.elements.input.value = "";
    this.elements.input.focus();
    this.applyFilter();
    this.selectFirst();
  }
};

CommandPalette.prototype.getCommandByElement = function(element) {
  for (var i = 0; i < this.commands.length; i++) {
    if (this.commands[i].element === element) return this.commands[i];
  }
};

CommandPalette.prototype.handleUlClick = function(event) {
  var element = event.target || event.srcElement;
  if (!element) return;
  if (element.nodeName === "SPAN") element = element.parentNode;
  if (element.nodeName === "I") element = element.parentNode;
  if (element.nodeName !== "LI") return;
  this.exec(this.getCommandByElement(element));
};

CommandPalette.prototype.exec = function(cmd) {
  if (!cmd) return;
  this.toggleDisplay(false);
  if (typeof cmd.action === "function"){
    cmd.action();
  } else {
    submitSapeventForm(null, cmd.action);
  }
};

/* COMMAND ENUMERATORS */

function createRepoCatalogEnumerator(catalog, action) {
  // expecting [{ key, isOffline, displayName }]
  return function() {
    return catalog.map(function(i) {
      return {
        action:    action + "?key=" + i.key,
        iconClass: i.isOffline
          ? "icon icon-plug darkgrey"
          : "icon icon-cloud-upload-alt blue",
        title: i.displayName
      };
    });
  };
}

function enumerateToolbarActions() {

  var items = [];
  function processUL(ulNode, prefix) {
    for (var i = 0; i < ulNode.children.length; i++) {
      var item = ulNode.children[i];
      if (item.nodeName !== "LI") continue; // unexpected node
      if (item.children.length >=2 && item.children[1].nodeName === "UL") {
        // submenu detected
        var menutext = item.children[0].innerText;
        // special treatment for menus without text
        if (!menutext) {
          menutext = item.children[0].getAttribute("title");
        }
        processUL(item.children[1], menutext);
      } else if (item.firstElementChild && item.firstElementChild.nodeName === "A") {
        var anchor = item.firstElementChild;
        if (anchor.href && anchor.href !== "#") items.push([anchor, prefix]);
      }
    }
  }

  var toolbarRoot = document.getElementById("toolbar-main");
  if (toolbarRoot && toolbarRoot.nodeName === "UL") processUL(toolbarRoot);
  toolbarRoot = document.getElementById("toolbar-repo");
  if (toolbarRoot && toolbarRoot.nodeName === "UL") processUL(toolbarRoot);
  // Add more toolbars ?
  if (items.length === 0) return;

  items = items.map(function(item) {
    var anchor = item[0];
    var prefix = item[1];
    return {
      action:    anchor.href.replace("sapevent:", ""),
      title:     (prefix ? prefix + ": " : "") + anchor.innerText.trim()
    };
  });

  return items;
}

function enumerateJumpAllFiles() {
  var root = document.getElementById("jump");
  if (!root || root.nodeName !== "UL") return null;

  return Array
    .prototype.slice.call(root.children)
    .filter(function(elem) { return elem.nodeName === "LI" })
    .map(function(listItem) {
      var title = listItem.children[0].childNodes[0].textContent;
      return {
        action: root.onclick.bind(null, title),
        title:  title
      };});
}

/* Save Scroll Position for Diff/Patch Page */

function saveScrollPosition(){
  if (!window.sessionStorage) { return }
  window.sessionStorage.setItem("scrollTop", document.querySelector("html").scrollTop);
}

function restoreScrollPosition(){
  if (!window.sessionStorage) { return }

  var scrollTop = window.sessionStorage.getItem("scrollTop");
  if (scrollTop) {
    document.querySelector("html").scrollTop = scrollTop;
  }
  window.sessionStorage.setItem("scrollTop", 0);
}

function memoizeScrollPosition(fn){
  return function(){
    saveScrollPosition();
    return fn.call(this, fn.args);
  }.bind(this);
}
