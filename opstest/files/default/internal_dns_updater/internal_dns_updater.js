/**
 * TODO: where are the following environment variables going to come from !? The App?
 *
 * The following environment variables are required and must be set:
 * - AWS_ACCESS_KEY_ID                     ------.
 * - AWS_SECRET_ACCESS_KEY                 ------|----> Needed for AWS access
 * - AWS_REGION (default: "us-west-2")     ------'
 * - INSTANCE_INTERNAL_IP
 * - R53_HOSTED_ZONE_ID
 * - SUBDOMAIN_FOR_RECORD_SET (desired subdomain name to go under the hosted zone domain)
 * - RECORD_SET_TTL (optional: defaults to 300s)
 */
const AWS = require('aws-sdk');
AWS.config.update({
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    region: process.env.AWS_REGION || "us-west-2",
    maxRetries: 3,
    retryDelayOptions: { base: 1000 }
});
const route53 = new AWS.Route53();

const hostedZoneId = process.env.R53_HOSTED_ZONE_ID;

async function listRecordSetForHostedZone(hostedZoneId) {
    const params = {
        HostedZoneId: hostedZoneId, /* required */
        // StartRecordType: 'A',
        // StartRecordName: 'lb-express'
    };
    const hostedZoneInfo = await route53.getHostedZone({Id: hostedZoneId}).promise();
    const recordSetsResponse = await route53.listResourceRecordSets(params).promise();
    // console.log(recordSetsResponse); // successful response
    return recordSetsResponse.ResourceRecordSets;
}

async function updateRecordSetForHostedZone() {
    const recordSetsForHostedZone = await listRecordSetForHostedZone(hostedZoneId);
    const aRecordSets = recordSetsForHostedZone.filter(record => record.Type==='A');

    const hostedZoneInfo = await route53.getHostedZone({Id: hostedZoneId}).promise();
    const hostedZoneName = hostedZoneInfo.HostedZone.Name;
    const subdomainForRecordSet = process.env.SUBDOMAIN_FOR_RECORD_SET || '';
    const recordSetName = `${subdomainForRecordSet}.${hostedZoneName}`;
    const instanceInternalIpAddr = process.env.INSTANCE_INTERNAL_IP;

    const instanceInternalIpAlreadyInRecordSet = aRecordSets.some(
        recordSet => recordSet.ResourceRecords[0].Value === instanceInternalIpAddr
    );

    if (instanceInternalIpAlreadyInRecordSet) {
        console.log(`No change neeeded. Instance internal IP already in recordset "${recordSetName}".`);
    } else {
        const recordSetTTL = parseInt(process.env.RECORD_SET_TTL || '300');
        let updateParams = {
            ChangeBatch: {
                Changes: [
                    {
                        Action: "CREATE",
                        ResourceRecordSet: {
                            Name: recordSetName,
                            MultiValueAnswer: true,
                            ResourceRecords: [{ Value: instanceInternalIpAddr }],
                            TTL: recordSetTTL,
                            Type: "A",
                            SetIdentifier: `recordset for internal ip ${instanceInternalIpAddr}`,
                        }
                    }
                ],
                Comment: ""
            },
            HostedZoneId: hostedZoneId
        };
        route53.changeResourceRecordSets(updateParams, function(err, data) {
            if (err) {
                console.log(err, err.stack); // an error occurred
            } else {
                // const aRecords = data.ResourceRecordSets.filter(record => record.Type==='A');
                console.log(data); // successful response
            }
        });
    }
}

updateRecordSetForHostedZone();
