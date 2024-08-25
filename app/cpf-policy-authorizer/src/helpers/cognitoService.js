import { CognitoIdentityProviderClient, AdminGetUserCommand, AdminListGroupsForUserCommand } from "@aws-sdk/client-cognito-identity-provider"; // ES Modules import

const UserPoolId = process.env.USER_POOL_ID;
const client = new CognitoIdentityProviderClient({
    region: process.env.REGION,
});

export const getUser = async (username) => {
    console.info("searching user by username: ", username);
    try {
        const command = new AdminGetUserCommand({
            UserPoolId,
            Username: username,
        });

        const cognitoUser = await client.send(command);
        console.log({ cognitoUser })
        return mapCognitoUserAttributes(cognitoUser.UserAttributes);
    } catch (error) {
        console.error(error);
        return null;
    }
}

const mapCognitoUserAttributes = (userAttributes) => userAttributes.reduce((prev, cuur,) => ({
    ...prev,
    [cuur.Name]: cuur.Value
}), {});

export const isAdmin = (userGroups) => userGroups.indexOf("admin") >= 0;

export const getUserGroups = async (username) => {
    console.info("searching user groups: ", username);

    const command = new AdminListGroupsForUserCommand({
        UserPoolId,
        Username: username,
    });
    var response = await client.send(command);
    return response?.Groups
        .map(r => r.GroupName) ?? [];
}