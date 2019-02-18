//const routes = (module.exports = require('next-routes')());
const routes = require('next-routes')();

routes
    .add('/producers/:address/assets/view' , 'producers/assets/view')
    .add('/producers/:address/assets/create' , 'producers/assets/create')
    .add('/assets/:address', 'assets/index')
    .add('/transporters/:address/assets/pending', 'transporters/assets/pending')
    .add('/transporters/:address/assets/active', 'transporters/assets/active')
    .add('/transporters/:address/assets/ending', 'transporters/assets/ending')
    .add('/shops/:address/assets/view' , 'shops/assets/view')
    .add('/shops/:address/assets/create' , 'shops/assets/pending')

    
module.exports = routes;