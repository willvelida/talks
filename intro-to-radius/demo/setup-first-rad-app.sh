# initialize rad environment
rad init

# inspect application
rad app show myapp -o json

# look for connections
rad app connections

# deploy rad app
rad deploy app.bicep

# again, inspect connections and see the difference

# run your rad app
rad run app.bicep

# show underlying recipe
rad recipe show default --resource-type Applications.Datastores/mongoDatabases

# run rad app
rad run app.bicep

# view connections
rad app connections

# run rad app
rad run app.bicep

# deploy rad app
rad deploy app.bicep