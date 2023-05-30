const fs = require('fs');
const yaml = require('js-yaml');

let fileContents = fs.readFileSync('config.yml', 'utf8');
let azhopConfig = yaml.load(fileContents);
console.log('Running tests on ' + azhopConfig.resource_group);

export default azhopConfig;
