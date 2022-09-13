var express = require('express');
var app = express();
var port = process.env.PORT || 9052;
var router = express.Router();

var bodyParser = require('body-parser');
var cors = require('cors');
var router = express.Router();

/*--------------------------middlewares--------------------------------------------------*/

app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));
app.use(cors());

router.use(function (req, res, next) {
    next();
});

/*---------------------------routes------------------------------------------------------*/


app.use('/sxtNode', router);
app.listen(port);
console.log('Space and Time node is running on ' + port);