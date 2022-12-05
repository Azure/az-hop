This role contains all applications integrated in Open OnDemand with AzHOP.
To add a new application named `my_app`:
 - Copy all your specific application files under ./files/`my_app`
 - Add any package dependencies in `./tasks/main.yml`
 - Add an entry in the `ood_azhop_apps` variable in `./defaults/main.yml` with `name: "my_app"` and set the enabled flag based on the app requirements
 