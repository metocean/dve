// Generated by CoffeeScript 1.9.3

/*

Add a title to your visualisations.

- type: title
  text: Wind Speed (kts)
 */
var changeTabClosure, d3, mount, unique;

d3 = require('d3');

unique = require('../util/unique');

mount = require('./mount');

changeTabClosure = function(title, component) {
  return function(event) {
    component.activeTitle = title;
    component._updateTabs();
    return component._updateContent();
  };
};

module.exports = function(spec, components) {
  return {
    render: function(dom, state, params) {
      var t, titles;
      titles = (function() {
        var j, len, ref, results;
        ref = spec.tabs;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          t = ref[j];
          results.push(t.title);
        }
        return results;
      })();
      if (titles.length !== unique(titles).length) {
        throw 'Tab titles must be unique';
      }
      this.activeTitle = spec.tabs[0].title;
      this.dom = dom;
      this.state = state;
      this.params = params;
      return this._update();
    },
    _update: function() {
      this._renderTabs();
      return this._renderContent();
    },
    _renderTabs: function() {
      var a, child, i, j, k, len, len1, li, ref, ref1, specTab, ul;
      ul = document.createElement('ul');
      ul.className = 'tabs tabs--bootstrap';
      this.tabs = [];
      ref = spec.tabs;
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        specTab = ref[i];
        li = document.createElement('li');
        if (specTab.title === this.activeTitle) {
          li.classList.add('is-active');
        }
        li.setAttribute('data-title', specTab.title);
        a = document.createElement('a');
        a.href = '#!';
        a.innerHTML = specTab.title;
        a.addEventListener('click', changeTabClosure(specTab.title, this));
        li.appendChild(a);
        this.tabs.push(li);
      }
      ref1 = this.tabs;
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        child = ref1[k];
        ul.appendChild(child);
      }
      return this.dom.appendChild(ul);
    },
    _updateTabs: function() {
      var j, len, ref, results, tab;
      ref = this.tabs;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        tab = ref[j];
        if (tab.getAttribute('data-title') === this.activeTitle) {
          results.push(tab.classList.add('is-active'));
        } else {
          results.push(tab.classList.remove('is-active'));
        }
      }
      return results;
    },
    _renderContent: function() {
      this.tabContent = document.createElement('div');
      this.tabContent.className = 'tab-content';
      this.dom.appendChild(this.tabContent);
      return this._updateContent();
    },
    _updateContent: function() {
      var childItem, childSpec, j, len, ref, t;
      if (this.tabContent) {
        this.tabContent.innerHTML = '';
      }
      ref = spec.tabs;
      for (j = 0, len = ref.length; j < len; j++) {
        t = ref[j];
        if (t.title === this.activeTitle) {
          childSpec = t.spec;
        }
      }
      childItem = mount(childSpec, components);
      return childItem.render(this.tabContent, this.state, this.params);
    }
  };
};
