# Dependencies
express= require 'express'
compression= require 'compression'

# Environment
process.env.PORT?= 59798
cwd= __dirname
bundleExternal= yes

# Setup express
app= express()
app.use compression()
app.use express.static cwd+'/dist'

# Boot
app.listen process.env.PORT,->
  console.log 'Server running at http://localhost:%s',process.env.PORT
