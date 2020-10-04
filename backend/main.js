exports.handler = function (event, context, callback) {
   var response = {
      statusCode: 200,
      headers: {
         "Access-Control-Allow-Headers" : "Content-Type",
         "Access-Control-Allow-Origin": "http://${origin}",
         "Access-Control-Allow-Methods": "GET,POST"
      },
      body: '<p>Hello, world!</p>' //+ JSON.stringify(context) + "<p>" + JSON.stringify(event)
   }
   if (event.body) { response.body = "<p>Hello, " + event.body + "!</p>"; }
   callback(null, response);
}
