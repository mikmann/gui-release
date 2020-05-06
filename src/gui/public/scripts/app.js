class Task {
    constructor(data) {
        this.id = ko.observable(data.id);
        this.expression = ko.observable(data.expression);
        this.rpn = ko.observable(data.rpn);
        this.result = ko.observable(data.result);
        this.created_at = ko.observable(data.created_at);
    }
}

class TaskViewModel {
    constructor() {
        var self = this;
        // functions
        self.showLexer = ko.observable(false);
        self.showCalculator = ko.observable(false);
        self.showResult = ko.observable(false);
        self.showDatabase = ko.observable(false);

        // object and properties
        self.task = ko.observable();
        self.tasks = ko.observableArray([]);
        self.expression = ko.observable("((20+606)*(3*20)/5)");
        self.rpn = ko.observable("");
        self.result = ko.observable("");

        self.addVisible = function(object) {
            if (object == "lexer")
                this.showLexer(true);
            else if (object == "calculator")
                this.showCalculator(true);
            else if (object == "database")
                this.showDatabase(true);
        };

        self.sendLexer = function(url) {
            var expression = this.expression();
            var rpn = this.rpn;
            self.sendRequest("lexer", { expression: expression }, rpn, url, "POST")
        };

        self.sendCalculator = function(url) {
            var rpn = this.rpn();
            var result = this.result;
            self.sendRequest("calculator", { rpn: rpn }, result, url, "POST")
        };

        self.sendRequest = function(type, input, output, url, method) {
            this.addVisible(type);
            var request = $.ajax({
                url: url + "/" + type,
                dataType: "json",
                type: method,
                data: input,
            });

            request.done(function(data) {
                output(data);
                var result = { success: data }
                console.log(result);
            });

            request.fail(function(jqXHR) {
                var result = { status: jqXHR.status, error: jqXHR.statusText }
                console.log(result);
            });
        };

        self.getTasks = function() {
            var request = $.ajax({
                url: "http://localhost:5000/database/tasks",
                dataType: "json",
                type: "GET",
                data: {},
            });

            request.done(function(data) {
                var data = JSON.parse(data)
                var tasks = $.map(data, function(item) {
                    return new Task(item);
                });
                self.tasks(tasks);
                var result = { success: data }
                console.log(result);
            });

            request.fail(function(jqXHR) {
                var result = { status: jqXHR.status, error: jqXHR.statusText }
                console.log(result);
            });
        };

        self.deleteTask = function(task) {
            // Convert task into an JS object
            var jsTask = ko.toJS(task);
            self.tasks.remove(task);
            var request = $.ajax({
                url: "http://localhost:5000/database/tasks/" + jsTask.id,
                dataType: "json",
                type: "DELETE",
                data: { id: jsTask.id },
            });

            request.done(function(data) {
                var result = { success: data }
                console.log(result);
            });

            request.fail(function(jqXHR) {
                var result = { status: jqXHR.status, error: jqXHR.statusText }
                console.log(result);
            });
        };

        self.sendDatabase = function() {
            var task = new Task({
                expression: this.expression(),
                rpn: this.rpn(),
                result: this.result()
            });
            this.addVisible("database");
            var request = $.ajax({
                dataType: "json",
                type: "POST",
                data: { task: task },
                url: "http://localhost:5000/database/tasks",
            });

            request.done(function(data) {
                var result = { success: data }
                self.getTasks();
                console.log(result);

            });

            request.fail(function(jqXHR) {
                var result = { status: jqXHR.status, error: jqXHR.statusText }
                console.log(result);

            });
        }

        self.isAlive = function() {
            var request = $.ajax({
                dataType: "json",
                type: "GET",
                url: "http://localhost:5000/is_alive",
            });

            request.done(function(data) {
                data.forEach(element => {
                    if (element.alive) {
                        if (element.service == "database" && self.tasks() == null) {
                            self.getTasks();
                        }
                        $("#" + element.service + "-alive").removeClass("not-alive");
                        $("#alert-" + element.service).css("display", "none");

                    } else {
                        if (element.service == "database") {
                            self.tasks(null);
                        }
                        $("#" + element.service + "-alive").addClass("not-alive");
                        $("#alert-" + element.service).css("display", "block");
                    }
                });
                var result = { states: data };
                console.log(result);
                setTimeout(self.isAlive, 15000);
            });

            request.fail(function(jqXHR) {
                var result = { status: jqXHR.status, error: jqXHR.statusText }
                console.log(result);
                setTimeout(self.isAlive, 15000);
            });
        }
        self.getTasks();
        self.isAlive();
    }

}
//alert(service)
ko.applyBindings(new TaskViewModel());