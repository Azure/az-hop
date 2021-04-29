from flask import Flask, request, redirect
MyApp = Flask(__name__)

@MyApp.route("/")
def index():
    return redirect(request.host_url+"rnode/robinhood/80/robinhood")

if __name__ == "__main__":
    MyApp.run()
