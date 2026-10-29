module("luci.controller.dashboard", package.seeall)

function index()
    entry({"admin", "dashboard"}, template("dashboard/index"), _("仪表盘"), 1)
end

