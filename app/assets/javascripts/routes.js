(function() {
  var NodeTypes, ParameterMissing, Utils, createGlobalJsRoutesObject, defaults, root,
    __hasProp = {}.hasOwnProperty;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  ParameterMissing = function(message) {
    this.message = message;
  };

  ParameterMissing.prototype = new Error();

  defaults = {
    prefix: "",
    default_url_options: {}
  };

  NodeTypes = {"GROUP":1,"CAT":2,"SYMBOL":3,"OR":4,"STAR":5,"LITERAL":6,"SLASH":7,"DOT":8};

  Utils = {
    serialize: function(object, prefix) {
      var element, i, key, prop, result, s, _i, _len;

      if (prefix == null) {
        prefix = null;
      }
      if (!object) {
        return "";
      }
      if (!prefix && !(this.get_object_type(object) === "object")) {
        throw new Error("Url parameters should be a javascript hash");
      }
      if (root.jQuery) {
        result = root.jQuery.param(object);
        return (!result ? "" : result);
      }
      s = [];
      switch (this.get_object_type(object)) {
        case "array":
          for (i = _i = 0, _len = object.length; _i < _len; i = ++_i) {
            element = object[i];
            s.push(this.serialize(element, prefix + "[]"));
          }
          break;
        case "object":
          for (key in object) {
            if (!__hasProp.call(object, key)) continue;
            prop = object[key];
            if (!(prop != null)) {
              continue;
            }
            if (prefix != null) {
              key = "" + prefix + "[" + key + "]";
            }
            s.push(this.serialize(prop, key));
          }
          break;
        default:
          if (object) {
            s.push("" + (encodeURIComponent(prefix.toString())) + "=" + (encodeURIComponent(object.toString())));
          }
      }
      if (!s.length) {
        return "";
      }
      return s.join("&");
    },
    clean_path: function(path) {
      var last_index;

      path = path.split("://");
      last_index = path.length - 1;
      path[last_index] = path[last_index].replace(/\/+/g, "/");
      return path.join("://");
    },
    set_default_url_options: function(optional_parts, options) {
      var i, part, _i, _len, _results;

      _results = [];
      for (i = _i = 0, _len = optional_parts.length; _i < _len; i = ++_i) {
        part = optional_parts[i];
        if (!options.hasOwnProperty(part) && defaults.default_url_options.hasOwnProperty(part)) {
          _results.push(options[part] = defaults.default_url_options[part]);
        }
      }
      return _results;
    },
    extract_anchor: function(options) {
      var anchor;

      anchor = "";
      if (options.hasOwnProperty("anchor")) {
        anchor = "#" + options.anchor;
        delete options.anchor;
      }
      return anchor;
    },
    extract_trailing_slash: function(options) {
      var trailing_slash;

      trailing_slash = false;
      if (defaults.default_url_options.hasOwnProperty("trailing_slash")) {
        trailing_slash = defaults.default_url_options.trailing_slash;
      }
      if (options.hasOwnProperty("trailing_slash")) {
        trailing_slash = options.trailing_slash;
        delete options.trailing_slash;
      }
      return trailing_slash;
    },
    extract_options: function(number_of_params, args) {
      var last_el;

      last_el = args[args.length - 1];
      if (args.length > number_of_params || ((last_el != null) && "object" === this.get_object_type(last_el) && !this.look_like_serialized_model(last_el))) {
        return args.pop();
      } else {
        return {};
      }
    },
    look_like_serialized_model: function(object) {
      return "id" in object || "to_param" in object;
    },
    path_identifier: function(object) {
      var property;

      if (object === 0) {
        return "0";
      }
      if (!object) {
        return "";
      }
      property = object;
      if (this.get_object_type(object) === "object") {
        if ("to_param" in object) {
          property = object.to_param;
        } else if ("id" in object) {
          property = object.id;
        } else {
          property = object;
        }
        if (this.get_object_type(property) === "function") {
          property = property.call(object);
        }
      }
      return property.toString();
    },
    clone: function(obj) {
      var attr, copy, key;

      if ((obj == null) || "object" !== this.get_object_type(obj)) {
        return obj;
      }
      copy = obj.constructor();
      for (key in obj) {
        if (!__hasProp.call(obj, key)) continue;
        attr = obj[key];
        copy[key] = attr;
      }
      return copy;
    },
    prepare_parameters: function(required_parameters, actual_parameters, options) {
      var i, result, val, _i, _len;

      result = this.clone(options) || {};
      for (i = _i = 0, _len = required_parameters.length; _i < _len; i = ++_i) {
        val = required_parameters[i];
        if (i < actual_parameters.length) {
          result[val] = actual_parameters[i];
        }
      }
      return result;
    },
    build_path: function(required_parameters, optional_parts, route, args) {
      var anchor, opts, parameters, result, trailing_slash, url, url_params;

      args = Array.prototype.slice.call(args);
      opts = this.extract_options(required_parameters.length, args);
      if (args.length > required_parameters.length) {
        throw new Error("Too many parameters provided for path");
      }
      parameters = this.prepare_parameters(required_parameters, args, opts);
      this.set_default_url_options(optional_parts, parameters);
      anchor = this.extract_anchor(parameters);
      trailing_slash = this.extract_trailing_slash(parameters);
      result = "" + (this.get_prefix()) + (this.visit(route, parameters));
      url = Utils.clean_path("" + result);
      if (trailing_slash === true) {
        url = url.replace(/(.*?)[\/]?$/, "$1/");
      }
      if ((url_params = this.serialize(parameters)).length) {
        url += "?" + url_params;
      }
      url += anchor;
      return url;
    },
    visit: function(route, parameters, optional) {
      var left, left_part, right, right_part, type, value;

      if (optional == null) {
        optional = false;
      }
      type = route[0], left = route[1], right = route[2];
      switch (type) {
        case NodeTypes.GROUP:
          return this.visit(left, parameters, true);
        case NodeTypes.STAR:
          return this.visit_globbing(left, parameters, true);
        case NodeTypes.LITERAL:
        case NodeTypes.SLASH:
        case NodeTypes.DOT:
          return left;
        case NodeTypes.CAT:
          left_part = this.visit(left, parameters, optional);
          right_part = this.visit(right, parameters, optional);
          if (optional && !(left_part && right_part)) {
            return "";
          }
          return "" + left_part + right_part;
        case NodeTypes.SYMBOL:
          value = parameters[left];
          if (value != null) {
            delete parameters[left];
            return this.path_identifier(value);
          }
          if (optional) {
            return "";
          } else {
            throw new ParameterMissing("Route parameter missing: " + left);
          }
          break;
        default:
          throw new Error("Unknown Rails node type");
      }
    },
    build_path_spec: function(route, wildcard) {
      var left, right, type;

      if (wildcard == null) {
        wildcard = false;
      }
      type = route[0], left = route[1], right = route[2];
      switch (type) {
        case NodeTypes.GROUP:
          return "(" + (this.build_path_spec(left)) + ")";
        case NodeTypes.CAT:
          return "" + (this.build_path_spec(left)) + (this.build_path_spec(right));
        case NodeTypes.STAR:
          return this.build_path_spec(left, true);
        case NodeTypes.SYMBOL:
          if (wildcard === true) {
            return "" + (left[0] === '*' ? '' : '*') + left;
          } else {
            return ":" + left;
          }
          break;
        case NodeTypes.SLASH:
        case NodeTypes.DOT:
        case NodeTypes.LITERAL:
          return left;
        default:
          throw new Error("Unknown Rails node type");
      }
    },
    visit_globbing: function(route, parameters, optional) {
      var left, right, type, value;

      type = route[0], left = route[1], right = route[2];
      if (left.replace(/^\*/i, "") !== left) {
        route[1] = left = left.replace(/^\*/i, "");
      }
      value = parameters[left];
      if (value == null) {
        return this.visit(route, parameters, optional);
      }
      parameters[left] = (function() {
        switch (this.get_object_type(value)) {
          case "array":
            return value.join("/");
          default:
            return value;
        }
      }).call(this);
      return this.visit(route, parameters, optional);
    },
    get_prefix: function() {
      var prefix;

      prefix = defaults.prefix;
      if (prefix !== "") {
        prefix = (prefix.match("/$") ? prefix : "" + prefix + "/");
      }
      return prefix;
    },
    route: function(required_parts, optional_parts, route_spec) {
      var path_fn;

      path_fn = function() {
        return Utils.build_path(required_parts, optional_parts, route_spec, arguments);
      };
      path_fn.required_params = required_parts;
      path_fn.toString = function() {
        return Utils.build_path_spec(route_spec);
      };
      return path_fn;
    },
    _classToTypeCache: null,
    _classToType: function() {
      var name, _i, _len, _ref;

      if (this._classToTypeCache != null) {
        return this._classToTypeCache;
      }
      this._classToTypeCache = {};
      _ref = "Boolean Number String Function Array Date RegExp Object Error".split(" ");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        this._classToTypeCache["[object " + name + "]"] = name.toLowerCase();
      }
      return this._classToTypeCache;
    },
    get_object_type: function(obj) {
      if (root.jQuery && (root.jQuery.type != null)) {
        return root.jQuery.type(obj);
      }
      if (obj == null) {
        return "" + obj;
      }
      if (typeof obj === "object" || typeof obj === "function") {
        return this._classToType()[Object.prototype.toString.call(obj)] || "object";
      } else {
        return typeof obj;
      }
    }
  };

  createGlobalJsRoutesObject = function() {
    var namespace;

    namespace = function(mainRoot, namespaceString) {
      var current, parts;

      parts = (namespaceString ? namespaceString.split(".") : []);
      if (!parts.length) {
        return;
      }
      current = parts.shift();
      mainRoot[current] = mainRoot[current] || {};
      return namespace(mainRoot[current], parts.join("."));
    };
    namespace(root, "Routes");
    root.Routes = {
// about => /about(.:format)
  // function(options)
  about_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"about",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// activity_log => /activity_logs/:id(.:format)
  // function(id, options)
  activity_log_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"activity_logs",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// activity_logs => /activity_logs(.:format)
  // function(options)
  activity_logs_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"activity_logs",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// backdoor_login => /backdoor_login(.:format)
  // function(options)
  backdoor_login_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"backdoor_login",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// cancel_user_registration => /users/cancel(.:format)
  // function(options)
  cancel_user_registration_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"cancel",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// change_suggestion => /change_suggestions/:id(.:format)
  // function(id, options)
  change_suggestion_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"change_suggestions",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// change_suggestions => /change_suggestions(.:format)
  // function(options)
  change_suggestions_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"change_suggestions",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// comments_teacher => /teachers/:id/comments(.:format)
  // function(id, options)
  comments_teacher_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"comments",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// delete_all_notification_logs => /notification_logs/delete_all(.:format)
  // function(options)
  delete_all_notification_logs_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"notification_logs",false]],[7,"/",false]],[6,"delete_all",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// destroy_user_session => /users/sign_out(.:format)
  // function(options)
  destroy_user_session_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"sign_out",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_activity_log => /activity_logs/:id/edit(.:format)
  // function(id, options)
  edit_activity_log_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"activity_logs",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_break_request_pcc_break_request => /pcc_break_requests/:id/edit_break_request(.:format)
  // function(id, options)
  edit_break_request_pcc_break_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"pcc_break_requests",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit_break_request",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_change_suggestion => /change_suggestions/:id/edit(.:format)
  // function(id, options)
  edit_change_suggestion_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"change_suggestions",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_enquiry => /enquiries/:id/edit(.:format)
  // function(id, options)
  edit_enquiry_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"enquiries",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_kit => /kits/:id/edit(.:format)
  // function(id, options)
  edit_kit_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"kits",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_kit_schedule => /kit_schedules/:id/edit(.:format)
  // function(id, options)
  edit_kit_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"kit_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_notification => /notifications/:id/edit(.:format)
  // function(id, options)
  edit_notification_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"notifications",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_notification_log => /notification_logs/:id/edit(.:format)
  // function(id, options)
  edit_notification_log_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"notification_logs",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_pcc_break_request => /pcc_break_requests/:id/edit(.:format)
  // function(id, options)
  edit_pcc_break_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"pcc_break_requests",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_pcc_communication_request => /pcc_communication_requests/:id/edit(.:format)
  // function(id, options)
  edit_pcc_communication_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"pcc_communication_requests",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_pcc_travel_request => /pcc_travel_requests/:id/edit(.:format)
  // function(id, options)
  edit_pcc_travel_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"pcc_travel_requests",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_program => /programs/:id/edit(.:format)
  // function(id, options)
  edit_program_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_program_teacher_schedule => /program_teacher_schedules/:id/edit(.:format)
  // function(id, options)
  edit_program_teacher_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_teacher => /teachers/:id/edit(.:format)
  // function(id, options)
  edit_teacher_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_teacher_teacher_schedule => /teachers/:teacher_id/teacher_schedules/:id/edit(.:format)
  // function(teacher_id, id, options)
  edit_teacher_teacher_schedule_path: Utils.route(["teacher_id","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"teacher_id",false]],[7,"/",false]],[6,"teacher_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_travel_request_pcc_travel_request => /pcc_travel_requests/:id/edit_travel_request(.:format)
  // function(id, options)
  edit_travel_request_pcc_travel_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"pcc_travel_requests",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit_travel_request",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_travel_ticket => /travel_tickets/:id/edit(.:format)
  // function(id, options)
  edit_travel_ticket_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"travel_tickets",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_user_password => /users/password/edit(.:format)
  // function(options)
  edit_user_password_path: Utils.route([], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"password",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_user_registration => /users/edit(.:format)
  // function(options)
  edit_user_registration_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_venue => /venues/:id/edit(.:format)
  // function(id, options)
  edit_venue_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"venues",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// edit_venue_schedule => /venue_schedules/:id/edit(.:format)
  // function(id, options)
  edit_venue_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"venue_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// enquiries => /enquiries(.:format)
  // function(options)
  enquiries_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"enquiries",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// enquiry => /enquiries/:id(.:format)
  // function(id, options)
  enquiry_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"enquiries",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// kit => /kits/:id(.:format)
  // function(id, options)
  kit_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"kits",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// kit_schedule => /kit_schedules/:id(.:format)
  // function(id, options)
  kit_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"kit_schedules",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// kit_schedules => /kit_schedules(.:format)
  // function(options)
  kit_schedules_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"kit_schedules",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// kits => /kits(.:format)
  // function(options)
  kits_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"kits",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// login_as => /login_as(.:format)
  // function(options)
  login_as_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"login_as",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// login_as_other_user => /login_as_other_user(.:format)
  // function(options)
  login_as_other_user_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"login_as_other_user",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_activity_log => /activity_logs/new(.:format)
  // function(options)
  new_activity_log_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"activity_logs",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_change_suggestion => /change_suggestions/new(.:format)
  // function(options)
  new_change_suggestion_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"change_suggestions",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_enquiry => /enquiries/new(.:format)
  // function(options)
  new_enquiry_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"enquiries",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_kit => /kits/new(.:format)
  // function(options)
  new_kit_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"kits",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_kit_schedule => /kit_schedules/new(.:format)
  // function(options)
  new_kit_schedule_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"kit_schedules",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_notification => /notifications/new(.:format)
  // function(options)
  new_notification_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"notifications",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_notification_log => /notification_logs/new(.:format)
  // function(options)
  new_notification_log_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"notification_logs",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_pcc_break_request => /pcc_break_requests/new(.:format)
  // function(options)
  new_pcc_break_request_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_break_requests",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_pcc_communication_request => /pcc_communication_requests/new(.:format)
  // function(options)
  new_pcc_communication_request_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_communication_requests",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_pcc_travel_request => /pcc_travel_requests/new(.:format)
  // function(options)
  new_pcc_travel_request_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_travel_requests",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_program => /programs/new(.:format)
  // function(options)
  new_program_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_program_teacher_schedule => /program_teacher_schedules/new(.:format)
  // function(options)
  new_program_teacher_schedule_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_teacher => /teachers/new(.:format)
  // function(options)
  new_teacher_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_teacher_teacher_schedule => /teachers/:teacher_id/teacher_schedules/new(.:format)
  // function(teacher_id, options)
  new_teacher_teacher_schedule_path: Utils.route(["teacher_id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"teacher_id",false]],[7,"/",false]],[6,"teacher_schedules",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_travel_ticket => /travel_tickets/new(.:format)
  // function(options)
  new_travel_ticket_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"travel_tickets",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_user_password => /users/password/new(.:format)
  // function(options)
  new_user_password_path: Utils.route([], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"password",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_user_registration => /users/sign_up(.:format)
  // function(options)
  new_user_registration_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"sign_up",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_user_session => /users/sign_in(.:format)
  // function(options)
  new_user_session_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"sign_in",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_venue => /venues/new(.:format)
  // function(options)
  new_venue_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"venues",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// new_venue_schedule => /venue_schedules/new(.:format)
  // function(options)
  new_venue_schedule_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"venue_schedules",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// notification => /notifications/:id(.:format)
  // function(id, options)
  notification_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"notifications",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// notification_log => /notification_logs/:id(.:format)
  // function(id, options)
  notification_log_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"notification_logs",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// notification_logs => /notification_logs(.:format)
  // function(options)
  notification_logs_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"notification_logs",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// notifications => /notifications(.:format)
  // function(options)
  notifications_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"notifications",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_break_request => /pcc_break_requests/:id(.:format)
  // function(id, options)
  pcc_break_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_break_requests",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_break_requests => /pcc_break_requests(.:format)
  // function(options)
  pcc_break_requests_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"pcc_break_requests",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_communication_request => /pcc_communication_requests/:id(.:format)
  // function(id, options)
  pcc_communication_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_communication_requests",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_communication_requests => /pcc_communication_requests(.:format)
  // function(options)
  pcc_communication_requests_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"pcc_communication_requests",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_travel_request => /pcc_travel_requests/:id(.:format)
  // function(id, options)
  pcc_travel_request_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"pcc_travel_requests",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// pcc_travel_requests => /pcc_travel_requests(.:format)
  // function(options)
  pcc_travel_requests_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"pcc_travel_requests",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// program => /programs/:id(.:format)
  // function(id, options)
  program_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// program_teacher_schedule => /program_teacher_schedules/:id(.:format)
  // function(id, options)
  program_teacher_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// program_teacher_schedules => /program_teacher_schedules(.:format)
  // function(options)
  program_teacher_schedules_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// programs => /programs(.:format)
  // function(options)
  programs_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"programs",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.dashboard => /admin/
  // function(options)
  rails_admin_dashboard_path: Utils.route([], [], [2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]], arguments),
// rails_admin.index => /admin/:model_name(.:format)
  // function(model_name, options)
  rails_admin_index_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.new => /admin/:model_name/new(.:format)
  // function(model_name, options)
  rails_admin_new_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[6,"new",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.export => /admin/:model_name/export(.:format)
  // function(model_name, options)
  rails_admin_export_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[6,"export",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.bulk_delete => /admin/:model_name/bulk_delete(.:format)
  // function(model_name, options)
  rails_admin_bulk_delete_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[6,"bulk_delete",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.history_index => /admin/:model_name/history(.:format)
  // function(model_name, options)
  rails_admin_history_index_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[6,"history",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.bulk_action => /admin/:model_name/bulk_action(.:format)
  // function(model_name, options)
  rails_admin_bulk_action_path: Utils.route(["model_name"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[6,"bulk_action",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.show => /admin/:model_name/:id(.:format)
  // function(model_name, id, options)
  rails_admin_show_path: Utils.route(["model_name","id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.edit => /admin/:model_name/:id/edit(.:format)
  // function(model_name, id, options)
  rails_admin_edit_path: Utils.route(["model_name","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"edit",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.delete => /admin/:model_name/:id/delete(.:format)
  // function(model_name, id, options)
  rails_admin_delete_path: Utils.route(["model_name","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"delete",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.history_show => /admin/:model_name/:id/history(.:format)
  // function(model_name, id, options)
  rails_admin_history_show_path: Utils.route(["model_name","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"history",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_admin.show_in_app => /admin/:model_name/:id/show_in_app(.:format)
  // function(model_name, id, options)
  rails_admin_show_in_app_path: Utils.route(["model_name","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"admin",false]],[7,"/",false]],[3,"model_name",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"show_in_app",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// rails_info_properties => /rails/info/properties(.:format)
  // function(options)
  rails_info_properties_path: Utils.route([], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"rails",false]],[7,"/",false]],[6,"info",false]],[7,"/",false]],[6,"properties",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// registration_confirmation => /registration_confirmation(.:format)
  // function(options)
  registration_confirmation_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"registration_confirmation",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// reserve_kit_schedule => /kit_schedules/:id/reserve(.:format)
  // function(id, options)
  reserve_kit_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"kit_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"reserve",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// reserve_teacher_teacher_schedule => /teachers/:teacher_id/teacher_schedules/:id/reserve(.:format)
  // function(teacher_id, id, options)
  reserve_teacher_teacher_schedule_path: Utils.route(["teacher_id","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"teacher_id",false]],[7,"/",false]],[6,"teacher_schedules",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"reserve",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// root => /
  // function(options)
  root_path: Utils.route([], [], [7,"/",false], arguments),
// search_program => /programs/:id/search(.:format)
  // function(id, options)
  search_program_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"search",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// search_teacher => /teachers/:id/search(.:format)
  // function(id, options)
  search_teacher_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"id",false]],[7,"/",false]],[6,"search",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// teacher => /teachers/:id(.:format)
  // function(id, options)
  teacher_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// teacher_teacher_schedule => /teachers/:teacher_id/teacher_schedules/:id(.:format)
  // function(teacher_id, id, options)
  teacher_teacher_schedule_path: Utils.route(["teacher_id","id"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"teacher_id",false]],[7,"/",false]],[6,"teacher_schedules",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// teacher_teacher_schedules => /teachers/:teacher_id/teacher_schedules(.:format)
  // function(teacher_id, options)
  teacher_teacher_schedules_path: Utils.route(["teacher_id"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"teachers",false]],[7,"/",false]],[3,"teacher_id",false]],[7,"/",false]],[6,"teacher_schedules",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// teachers => /teachers(.:format)
  // function(options)
  teachers_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"teachers",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// travel_ticket => /travel_tickets/:id(.:format)
  // function(id, options)
  travel_ticket_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"travel_tickets",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// travel_tickets => /travel_tickets(.:format)
  // function(options)
  travel_tickets_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"travel_tickets",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_donations => /programs/update_program_donations(.:format)
  // function(options)
  update_program_donations_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[6,"update_program_donations",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_teacher_schedule_additional_comments => /program_teacher_schedules/update_additional_comments(.:format)
  // function(options)
  update_program_teacher_schedule_additional_comments_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[6,"update_additional_comments",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_teacher_schedule_blockable_programs => /program_teacher_schedules/update_blockable_programs(.:format)
  // function(options)
  update_program_teacher_schedule_blockable_programs_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[6,"update_blockable_programs",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_teacher_schedule_blockable_teachers => /program_teacher_schedules/update_blockable_teachers(.:format)
  // function(options)
  update_program_teacher_schedule_blockable_teachers_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[6,"update_blockable_teachers",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_teacher_schedule_program_timings => /program_teacher_schedules/update_program_timings(.:format)
  // function(options)
  update_program_teacher_schedule_program_timings_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"program_teacher_schedules",false]],[7,"/",false]],[6,"update_program_timings",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_program_timings => /programs/update_timings(.:format)
  // function(options)
  update_program_timings_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"programs",false]],[7,"/",false]],[6,"update_timings",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_teacher_schedule_centers => /teacher_schedules/update_centers(.:format)
  // function(options)
  update_teacher_schedule_centers_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"teacher_schedules",false]],[7,"/",false]],[6,"update_centers",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// update_teacher_schedule_timings => /teacher_schedules/update_timings(.:format)
  // function(options)
  update_teacher_schedule_timings_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"teacher_schedules",false]],[7,"/",false]],[6,"update_timings",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// user_omniauth_authorize => /users/auth/:provider(.:format)
  // function(provider, options)
  user_omniauth_authorize_path: Utils.route(["provider"], ["format"], [2,[2,[2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"auth",false]],[7,"/",false]],[3,"provider",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// user_omniauth_callback => /users/auth/:action/callback(.:format)
  // function(action, options)
  user_omniauth_callback_path: Utils.route(["action"], ["format"], [2,[2,[2,[2,[2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"auth",false]],[7,"/",false]],[3,"action",false]],[7,"/",false]],[6,"callback",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// user_password => /users/password(.:format)
  // function(options)
  user_password_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"password",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// user_registration => /users(.:format)
  // function(options)
  user_registration_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"users",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// user_session => /users/sign_in(.:format)
  // function(options)
  user_session_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"sign_in",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// users_autocomplete => /users/autocomplete(.:format)
  // function(options)
  users_autocomplete_path: Utils.route([], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"users",false]],[7,"/",false]],[6,"autocomplete",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// venue => /venues/:id(.:format)
  // function(id, options)
  venue_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"venues",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// venue_schedule => /venue_schedules/:id(.:format)
  // function(id, options)
  venue_schedule_path: Utils.route(["id"], ["format"], [2,[2,[2,[2,[7,"/",false],[6,"venue_schedules",false]],[7,"/",false]],[3,"id",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// venue_schedules => /venue_schedules(.:format)
  // function(options)
  venue_schedules_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"venue_schedules",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments),
// venues => /venues(.:format)
  // function(options)
  venues_path: Utils.route([], ["format"], [2,[2,[7,"/",false],[6,"venues",false]],[1,[2,[8,".",false],[3,"format",false]],false]], arguments)}
;
    root.Routes.options = defaults;
    return root.Routes;
  };

  if (typeof define === "function" && define.amd) {
    define([], function() {
      return createGlobalJsRoutesObject();
    });
  } else {
    createGlobalJsRoutesObject();
  }

}).call(this);
