'use strict';
'require baseclass';

var _started = false;

return baseclass.extend({
	title: _('温度与网速'),

	load: function() {
		return Promise.resolve();
	},

	render: function() {
		var table = E('table', { 'class': 'table' }, [
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, _('芯片温度')),
				E('td', { 'class': 'td left', 'id': 'dash-temp' }, _('读取中...'))
			]),
			E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%' }, _('实时网速')),
				E('td', { 'class': 'td left', 'id': 'dash-net' }, _('读取中...'))
			])
		]);

		var prev = {};
		var prevTime = Date.now();

		function fmtSpeed(bytes, sec) {
			var bps = bytes / sec;
			if (bps >= 1048576)
				return (bps / 1048576).toFixed(2) + ' MB/s';
			if (bps >= 1024)
				return (bps / 1024).toFixed(1) + ' KB/s';
			return Math.round(bps) + ' B/s';
		}

		function update() {
			fetch('/cgi-bin/dashboard-data', { cache: 'no-store' })
				.then(function(r) { return r.json(); })
				.catch(function() { return null; })
				.then(function(d) {
					var tempEl = document.getElementById('dash-temp');
					var netEl = document.getElementById('dash-net');
					if (!tempEl || !netEl || !d)
						return;

					if (d.temps && d.temps.length > 0) {
						tempEl.textContent = d.temps.map(function(t) {
							var color = t.temp >= 80 ? ' style="color:#dc2626;font-weight:600"' :
								t.temp >= 65 ? ' style="color:#d97706;font-weight:600"' :
								' style="color:#16a34a;font-weight:600"';
							return '<span' + color + '>' + t.temp + '&deg;C</span> <small>' + t.name + '</small>';
						}).join('&nbsp;&nbsp;');
					}
					else {
						tempEl.textContent = _('未检测到温度传感器');
					}

					var now = Date.now();
					var sec = Math.max((now - prevTime) / 1000, 1);
					prevTime = now;
					var parts = [];
					(d.network || []).forEach(function(iface) {
						if (iface.state !== 'up')
							return;
						var p = prev[iface.name] || { rx: 0, tx: 0 };
						var rxs = (iface.rx > p.rx) ? (iface.rx - p.rx) : 0;
						var txs = (iface.tx > p.tx) ? (iface.tx - p.tx) : 0;
						prev[iface.name] = { rx: iface.rx, tx: iface.tx };
						parts.push('<span style="color:#2563eb;font-weight:600">' + iface.name +
							'</span> &darr;' + fmtSpeed(rxs, sec) +
							' &uarr;' + fmtSpeed(txs, sec));
					});
					netEl.innerHTML = parts.length
						? parts.join('<br/>')
						: _('无活动接口');
				});
		}

		if (!_started) {
			_started = true;
			setInterval(update, 3000);
		}

		update();

		return table;
	}
});

