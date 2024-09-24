import { generateAccessToken } from '../helpers/tokenService.js';
import { getUser, getUserGroups } from '../helpers/cognitoService.js';
import { generateAuthPolicy } from '../helpers/policyHelper.js';
import { v4 as uuidv4 } from 'uuid';

// https://stackoverflow.com/questions/40585016/is-it-possible-to-add-an-http-header-from-aws-custom-auth-on-api-gateway
// https://stackoverflow.com/questions/68959135/read-jwt-token-from-different-http-header-in-asp-net-core
export const handler = async (event, context, callback) => {
    const cpf = event.headers.cpf
    const identityProvided = !!cpf;

    if (identityProvided) {
        const user = await getUser(cpf);

        if (user) {
            let userGroups = await getUserGroups(cpf);
            let jwtPayload = {
                cpf,
                ...user,
                role: userGroups
            }

            let token = generateAccessToken(jwtPayload);
            let policy = generateAuthPolicy(cpf, event.routeArn, token);
            console.log(token);

            return policy;
        } else {
            callback("Unauthorized", null);
        }
    } else {
        let token = generateAccessToken({
            role: ["customer"]
        });
        return generateAuthPolicy(uuidv4(), event.routeArn, token);
    }
};
