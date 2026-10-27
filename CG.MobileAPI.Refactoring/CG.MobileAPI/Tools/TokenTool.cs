using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography.Xml;
using System.Text;

namespace CG.MobileAPI.Tools
{
    public static class TokenTool
    {
        public static string CryptedKey = "enh0aHFld2dnMWM0OW0xZ3d5Nm5tOWJhczVrZHQ2MTZqajd2bnF0Y3drNTY4NDBxOWhyZm52dDJ0Mjlid3VrenY0ZTI3MzR2d25lcHBzeDFtbmNuZnhiODVtMXVtNzV4YXh1NjR1NWcycXo3Ym5qNm1maDhzcTNja3JvcjlrYXU=";
        public static string TokenIssuer = "CasagrandeAuthServer";
        public static string TokenAudience = "casagrande-utilities-application";

        public static string GeneraTokenJwt(string username)
        {
            return GeneraTokenJwt(username, new Dictionary<string, string>());
        }

        /// <summary>
        /// Genera il token JWT con dei claim aggiuntivi (es. nomePortale e accountType dell'app mobile).
        /// </summary>
        /// <param name="username">Nome utente (claim Name).</param>
        /// <param name="extraClaims">Claim aggiuntivi tipo/valore.</param>
        public static string GeneraTokenJwt(string username, IDictionary<string, string> extraClaims)
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, username),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };
            claims.AddRange(extraClaims.Select(c => new Claim(c.Key, c.Value ?? "")));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(CryptedKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: TokenIssuer,
                audience: TokenAudience,
                claims: claims,
                expires: DateTime.UtcNow.AddHours(8), 
                signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
