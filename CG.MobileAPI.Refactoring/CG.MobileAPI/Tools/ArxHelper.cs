using System.Collections;
using System.Configuration;
using System.Text.Json;
using System.Threading.Channels;
using Abletech.WebApi.Client.Arxivar.Api;
using Abletech.WebApi.Client.Arxivar.Client;
using Abletech.WebApi.Client.Arxivar.Model;
using CG.MobileAPI.ExceptionModels;
using Newtonsoft.Json.Linq;
using RestSharp;
using Configuration = Abletech.WebApi.Client.Arxivar.Client.Configuration;

namespace CG.MobileAPI.Tools
{
    public static class ArxHelper
    {
        private static string arxivarApiBasePath = "https://arx.casagrandegroup.com/ARXivarNextWebApi"; // ARXivarNEXT URL For INTERNAL USE
        private static string arxivarUsername = "API_PortaleUtilities";
        private static string arxivarPassword = "S%$uzUb2ZG";

        private static string arxivarClientSecret = "1013FFEF120746FE93214244EDB7E02F";

        private static string arxivarAooCode = "CSG";


        /// <summary>
        /// Costruisce e configura una ricerca documentale parametrica utilizzando l'API SearchesV3 di Arxivar Next.
        /// Content deve contenere i seguenti campi:
        /// <list type="bullet">
        ///   <item><description><b>idDocFather</b>: ID della classe padre del documento (int)</description></item>
        ///   <item><description><b>idDoc</b>: ID del documento (int)</description></item>
        ///   <item><description><b>searchFields</b>: Array di ArxSearchElement contenenti i criteri di ricerca</description>
        ///   </item>
        ///   <item><description><b>selectFields</b>: Array di ArxSelectElement contenenti i campi da selezionare nei risultati</description>
        ///   </item>
        ///   <item><description><b>societa</b>: Codice della società per cui eseguire la ricerca(CSG/HUT/CSU)</description></item>
        /// </list>
        /// </summary>
        /// <param name="configuration">Configurazione per l'API Arxivar.</param>
        /// <param name="selectDTO"><b>Output</b>: oggetto contenente i campi selezionabili configurati per la ricerca.</param>
        /// <param name="searchDTO"><b>Output</b>: lista di criteri di ricerca configurati sulla base dei filtri forniti.</param>
        /// <param name="content">
        /// Dizionario JSON con i parametri richiesti per costruire la ricerca.
        /// </param>
        /// <returns>
        /// Un'istanza di <see cref="SearchesV3Api"/> con configurazione e criteri di ricerca pronti all'uso.
        /// </returns>
        /// <exception cref="ArxException">Sollevata se i dati nel parametro <paramref name="content"/> non sono corretti o incompleti.</exception>
        static SearchesV3Api BuildDocumentDTOs(Configuration configuration, out SelectDTO selectDTO, out List<SearchDTO> searchDTO, Dictionary<string, JsonElement> content)
        {
            var searchesApi = new SearchesV3Api(arxivarApiBasePath);
            searchesApi.Configuration = configuration;

            //Verifico che content abbia i campi obbligatori
            if (!content.ContainsKey("idDocFather") || !content.ContainsKey("idDoc") || !content.ContainsKey("searchFields") || !content.ContainsKey("selectFields") || !content.ContainsKey("societa"))
            {
                throw new ArxException("Formato contenuto errato");
            }

            //Contiene tutti i campi che fanno da filtro
            ArxSearchElement[] searchFields = content["searchFields"].EnumerateArray().Select(i => JsonSerializer.Deserialize<ArxSearchElement>(i.GetRawText())).ToArray();

            //Contiene i campi che devono essere selezionati
            ArxSelectElement[] selectFields = content["selectFields"].EnumerateArray().Select(i => JsonSerializer.Deserialize<ArxSelectElement>(i.GetRawText())).ToArray();

            //Identificativi della classe documentale
            int idDocFather = content["idDocFather"].GetInt32();
            int idDoc = content["idDoc"].GetInt32();


            selectDTO = searchesApi.SearchesV3GetSelect_1(idDocFather, idDoc, 0);

            var searchV3DTOBuilder = new SearchV3DTOBuilder(searchesApi);

            //Lista dei campi base che hanno tutte le classi documentali
            var listFieldBaseForSearchDTO = searchV3DTOBuilder.SearchDTO.Fields.ToArray();
            //Lista dei campi aggiuntivi che ha la classe documentale specificata
            var listFieldAdditionForSearchDTO = searchesApi.SearchesV3GetAdditionalByClasse(idDocFather, idDoc, 0, content["societa"].ToString());

            searchV3DTOBuilder.SearchDTO.Fields.Clear();

            //Aggiungo i filtri sui Campi del documento
            //Al momento non sono implementati i campi di tipo DateTime e Integer, quindi non li gestisco
            foreach (ArxSearchElement field in searchFields)
            {


                if (field.IsBase)//Aggiungo i filtri sui Campi base del documento
                {
                    foreach (var itm in listFieldBaseForSearchDTO)
                    {
                        switch (itm.Name)
                        {
                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchInt") && field.Type.Equals("int"):
                                searchV3DTOBuilder.AddFieldBaseForSearchInt(itm, int.Parse(field.Value), null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchString") && field.Type.Equals("string"):
                                searchV3DTOBuilder.AddFieldBaseForSearchString(itm, field.Value, null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchBool") && field.Type.Equals("bool"):
                                searchV3DTOBuilder.AddFieldBaseForSearchBool(itm, field.Value == "Y", null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchList") && field.Type.Equals("list"):
                                searchV3DTOBuilder.AddFieldBaseForSearchList(itm, field.Value, null, field.Operator);
                                break;
                        }
                    }
                }
                else // Aggiungo i filtri sui Campi aggiuntivi del documento
                {
                    foreach (var itm in listFieldAdditionForSearchDTO)
                    {
                        switch (itm.Name)
                        {
                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchInt") && field.Type.Equals("int"):
                                searchV3DTOBuilder.AddFieldBaseForSearchInt(itm, int.Parse(field.Value), null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchString") && field.Type.Equals("string"):
                                searchV3DTOBuilder.AddFieldBaseForSearchString(itm, field.Value, null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchBool") && field.Type.Equals("bool"):
                                searchV3DTOBuilder.AddFieldBaseForSearchBool(itm, field.Value == "Y", null, field.Operator);
                                break;

                            case string str when str.Equals(field.Name) &&
                                itm.ClassName.Contains("FieldBaseForSearchList") && field.Type.Equals("list"):
                                searchV3DTOBuilder.AddFieldBaseForSearchList(itm, field.Value, null, field.Operator);
                                break;
                        }
                    }
                }
            }



            //Scandisco tutti i campi presenti nella classe documentale
            selectDTO.Fields.ForEach(itm =>
            {
                //Abilito solo i campi selezionati
                for (int i = 0; i < selectFields.Length; i++)
                {
                    // Controllo se il campo è presente nella lista dei campi selezionati
                    if (String.Equals(itm.Name, selectFields[i].Name))
                    {
                        itm.Selected = selectFields[i].Selected;
                        itm.Index = selectFields[i].Index;
                        itm.OrderBy = new OrderBy() { Direction = selectFields[i].OrderBy == "asc" ? 1 : 2 };
                        break;
                    }
                    else
                    {
                        itm.Selected = false;
                    }
                }
            });

            searchDTO = searchV3DTOBuilder.Build();

            return searchesApi;
        }

        /// <summary>
        /// Invia un file ad ARXivar associandolo a un profilo documento, impostando i possibili campi aggiuntivi.
        /// </summary>
        /// <param name="filePath">Percorso assoluto del file da caricare, il percorso è nullo in caso si voglia fare riferimento ad un documento già esistente</param>
        /// <param name="content">
        /// Dizionario contenente i seguenti campi obbligatori:
        /// <code>
        /// - idDocFather: ID della classe documentale (int)
        /// - idDoc: ID secondario della classe documentale (int)
        /// - stateValue: Codice dello stato documento (es. VALID)
        /// - isDocument: "Y" se si vuole archiviare un documento già esistente, "N" se si carica da file
        /// - docFields: Array di oggetti JSON con i campi da valorizzare
        /// </code>
        /// Ogni elemento di <c>DocFields</c> deve essere una struttura:
        /// <code>
        /// - nameField: Nome del campo aggiuntivo (es. TESTO126_33),
        /// - typeField: Tipo del campo aggiuntivo, i valori accettati sono (TESTO, COMBO, DATA, CHECK, TABLE, INT, DOUBLE, CLASSE, GROUP),
        /// - valueField: Effettivo valore da inserire nel campo, il formato dipende dal tipo di campo.
        /// }
        /// </code>
        /// </param>
        /// <returns>
        /// Il numero del documento ARXivar archiviato, oppure stringa vuota se si è verificato un errore.
        /// </returns>
        /// <exception cref="ArxException">
        /// Sollevata quando i dati obbligatori sono assenti o invalidi, o il tipo campo non è supportato.
        /// </exception>
        public static string SendFileToArx(string filePath, Dictionary<string, JsonElement> content)
        {

            try
            {
                //Connessione ad ARXivar
                string arxFileName = "";
                Configuration configuration = new Configuration()
                {
                    BasePath = arxivarApiBasePath
                };

                var authApi = new AuthenticationApi(configuration);

                //Token di autenticazione
                var authenticationTokenRequestDTO = new AuthenticationTokenRequestDTO();
                authenticationTokenRequestDTO.Username = arxivarUsername;
                authenticationTokenRequestDTO.Password = arxivarPassword;
                authenticationTokenRequestDTO.ClientId = "ArxivarNextDev";
                authenticationTokenRequestDTO.ClientSecret = arxivarClientSecret;


                var arxToken = authApi.AuthenticationGetToken(authenticationTokenRequestDTO);

                configuration.ApiClient.RestClient.AddDefaultHeader("Authorization", "Bearer " + arxToken.AccessToken);

                var bufferApi = new BufferApi(configuration);
                var profileApi = new ProfilesApi(configuration);
                var statesApi = new StatesApi(configuration);

                var docTypesApi = new DocumentTypesApi(configuration);
                var doctypes = docTypesApi.DocumentTypesGet_0(1, arxivarAooCode);

                using (var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
                {

                    if (!content.ContainsKey("idDocFather") || !content.ContainsKey("idDoc") || !content.ContainsKey("stateValue") ||
                        !content.ContainsKey("isDocument") || !content.ContainsKey("docFields"))
                    {
                        throw new ArxException("Formato contenuto errato");
                    }


                    var profileDto = profileApi.ProfilesGet_0();
                    // Fix for CS0030: Non è possibile convertire il tipo 'string' in 'int'  
                    var classeFORDOR = doctypes.FirstOrDefault(i => i.IdParent == content["idDocFather"].GetInt32() && i.Id == content["idDoc"].GetInt32());
                    var status = statesApi.StatesGet_0();
                    List<string> bufferIds = [];
                    string statoValue = content["stateValue"].GetString();
                    bool isDocument = content["isDocument"].ToString() == "Y";


                    if (statoValue == null || classeFORDOR == null)
                    {
                        throw new ArxException("Dati inseriti errati o assenti");
                    }


                    Dictionary<string, string>[] DocFields = content["docFields"].EnumerateArray().Select(i => JsonSerializer.Deserialize<Dictionary<string, string>>(i.GetRawText())).ToArray();

                    ((StateFieldDTO)profileDto.Fields.FirstOrDefault(i => i.Name.Equals("Stato", StringComparison.CurrentCultureIgnoreCase))).Value = status.Where(s => s.Id.Equals(statoValue)).FirstOrDefault().Id;

                    ((DocumentTypeFieldDTO)profileDto.Fields.FirstOrDefault(i => i.Name.Equals("DocumentType"))).Value = classeFORDOR.Id;

                    ((OriginFieldDTO)profileDto.Fields.FirstOrDefault(i => i.Name.Equals("Origine", StringComparison.CurrentCultureIgnoreCase))).Value = 0;

                    if (!isDocument)
                    {
                        bufferIds = bufferApi.BufferInsert(fileStream);
                    }

                    Dictionary<string, Action<FieldBaseDTO>> profileFieldValues = new Dictionary<string, Action<FieldBaseDTO>>();

                    //Informazioni di inserimento
                    foreach (Dictionary<string, string> field in DocFields)
                    {
                        //Se i campi non sono presenti nel dizionario, lancio un'eccezione
                        if (!field.ContainsKey("typeField") || !field.ContainsKey("nameField") || !field.ContainsKey("valueField"))
                        {
                            throw new ArxException("campi documento errati o assenti");
                        }

                        switch (field["typeField"].ToUpper())
                        {
                            case "TESTO":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldStringDTO)f).Value = field["valueField"];
                                });
                                break;

                            case "COMBO":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldComboDTO)f).Value = field["valueField"];
                                });
                                break;

                            case "DATA":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldDateTimeDTO)f).Value = DateTime.ParseExact(field["valueField"], "yyyyMMdd", null);
                                });
                                break;

                            case "CHECK":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldBooleanDTO)f).Value = field["valueField"] == "Y";
                                });
                                break;

                            case "TABLE":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldTableDTO)f).Value = field["valueField"];
                                });
                                break;

                            case "INT":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldIntDTO)f).Value = int.Parse(field["valueField"]);
                                });
                                break;

                            case "DOUBLE":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldDoubleDTO)f).Value = double.Parse(field["valueField"]);
                                });
                                break;

                            case "CLASSE":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldClasseDTO)f).Value = field["valueField"].Split(',').Select(value => (int?)int.Parse(value)).ToList();
                                });
                                break;

                            case "GROUP":
                                profileFieldValues.Add(field["nameField"], delegate (FieldBaseDTO f)
                                {
                                    ((AdditionalFieldGroupDTO)f).Value = field["valueField"];
                                });
                                break;

                            default:
                                throw new ArxException("Tipo di campo non supportato: " + field["typeField"]);
                        }
                    }

                    var additional = profileApi.ProfilesGetAdditionalByClasse(classeFORDOR.DocumentType, classeFORDOR.Type2, classeFORDOR.Type3, arxivarAooCode);
                    profileDto.Fields.AddRange(additional);

                    profileDto.Fields.ForEach(f =>
                    {
                        if (profileFieldValues.ContainsKey(f.Name.ToUpperInvariant()))
                        {
                            profileFieldValues[f.Name.ToUpperInvariant()](f);
                        }
                    });

                    //Console.WriteLine(String.Join(",", profileDto.Fields.ToList()));
                    var profilePost = new ProfileDTO()
                    {
                        Fields = profileDto.Fields,
                        AuthorityData = new AuthorityDataDTO(),
                        Attachments = new List<string>(),
                        Notes = new List<NoteDTO>(),
                        PaNotes = new List<string>(),
                        PostProfilationActions = new List<PostProfilationActionDTO>()
                    };

                    if (!isDocument)
                    {
                        profilePost.Document = new FileDTO() { BufferIds = bufferIds };
                    }

                    //Converto il post in JSON
                    var jsonString = profilePost.ToJson();
                    //Archivio il nuovo documento
                    var result = profileApi.ProfilesPost(profilePost);

                    arxFileName = result.DocNumber.ToString();

                    Console.WriteLine(String.Format("Result JSON format: {0}", result.ToJson()));

                }
                //Eliminazione del file temporaneo
                File.Delete(filePath);

                return arxFileName;
            }
            catch (Exception e)
            {
                return "";
            }
        }
        
        
        /// <summary>
        /// Data una lista di systemId, ritorna i file relative
        /// </summary>
        /// <param name="systemIdList"></param>
        /// <returns></returns>
        /// <exception cref="ArxException"></exception>
        public static async Task<List<byte[]>> GetArxFiles(List<int> systemIdList)
        {
            try
            {
                //Configurazione d'accesso ad ARXivar
                Configuration configuration = new Configuration()
                {
                    BasePath = arxivarApiBasePath
                };

                var authApi = new AuthenticationApi(configuration);

                var authenticationTokenRequestDTO = new AuthenticationTokenRequestDTO();
                authenticationTokenRequestDTO.Username = arxivarUsername;
                authenticationTokenRequestDTO.Password = arxivarPassword;
                authenticationTokenRequestDTO.ClientId = "ArxivarNextDev";
                authenticationTokenRequestDTO.ClientSecret = arxivarClientSecret;

                var arxToken = await authApi.AuthenticationGetTokenAsync(authenticationTokenRequestDTO);

                configuration.ApiClient.RestClient.AddDefaultHeader("Authorization", "Bearer " + arxToken.AccessToken);

                var documentsApi = new Abletech.WebApi.Client.Arxivar.Api.DocumentsApi(configuration);



                List<byte[]> response = new();

                foreach (int systemId in systemIdList)
                {
                    //Estraggo il file associato al systemId
                    ApiResponse<Stream> file = await Task.Run(() => documentsApi.DocumentsGetForProfileWithHttpInfo(systemId, false));

                    if (file.StatusCode == 200)
                    {
                        var removedChars = new string[] { "\"", "[", "]" };
                        var fileName = file.Headers["Content-Disposition"].Replace("attachment; filename=", String.Empty);
                        removedChars.ToList().ForEach(chr => fileName = fileName.Replace(chr, String.Empty));

                        fileName = fileName.Replace("upload_", "download_");
                        var fileFullPath = @"C:\tmp\uploadFiles\" + fileName;

                        using (var memoryStream = new MemoryStream())
                        {
                            file.Data.CopyTo(memoryStream);
                            response.Add(memoryStream.ToArray());
                        }

                        file.Data.Dispose();
                    }
                    else
                    {
                        throw new ArxException("Documento con systemId: " + systemId + " non trovato");
                    }
                }

                return response;


            }
            catch (Exception e)
            {
                throw new ArxException("ATTENIONE: Connessione ad ARXivar non riuscita. Contattare l'ufficio IT.");
            }
        }

        /// <summary>
        /// Data un systemId, ritorna il file relativo
        /// </summary>
        /// <param name="systemID"></param>
        /// <returns></returns>
        public static async Task<List<byte[]>> GetArxFiles(int systemID)
        {
            try
            {
                Configuration configuration = new Configuration()
                {
                    BasePath = arxivarApiBasePath
                };

                var authApi = new AuthenticationApi(configuration);

                var authenticationTokenRequestDTO = new AuthenticationTokenRequestDTO();
                authenticationTokenRequestDTO.Username = arxivarUsername;
                authenticationTokenRequestDTO.Password = arxivarPassword;
                authenticationTokenRequestDTO.ClientId = "ArxivarNextDev";
                authenticationTokenRequestDTO.ClientSecret = arxivarClientSecret;

                var arxToken = await authApi.AuthenticationGetTokenAsync(authenticationTokenRequestDTO);

                configuration.ApiClient.RestClient.AddDefaultHeader("Authorization", "Bearer " + arxToken.AccessToken);

                var documentsApi = new Abletech.WebApi.Client.Arxivar.Api.DocumentsApi(configuration);



                // Recupero i dati da Arxivar

                List<byte[]> response = new();
                
                //Il primo campo è il SystemId del documento
                var file = await Task.Run(() => documentsApi.DocumentsGetForProfileWithHttpInfo(systemID, false));

                if (file.StatusCode == 200)
                {
                    var removedChars = new string[] { "\"", "[", "]" };
                    var fileName = file.Headers["Content-Disposition"].Replace("attachment; filename=", String.Empty);

                    removedChars.ToList().ForEach(chr => fileName = fileName.Replace(chr, String.Empty));

                    fileName = fileName.Replace("upload_", "download_");
                    var fileFullPath = @"C:\tmp\uploadFiles\" + fileName;

                    response.Add(StreamToByteArray(file.Data));
                }
                else
                {
                    throw (new ArxException("ATTENZIONE: nessun documento Arxivar trovato"));
                }

                return response;


            }
            catch (Exception e)
            {
                throw (new ArxException("ATTENIONE: Connessione ad ARXivar non riuscita. Contattare l'ufficio IT."));
            }
        }


        /// <summary>
        /// Elimina il documento Arixivar specificato dal SystemId
        /// </summary>
        /// <param name="systemId">systemId del documento</param>
        /// <returns></returns>
        public static bool DeleteFileFromArx(int systemId)
        {

            try
            {
                //Configurazione d'accesso
                Configuration configuration = new Configuration()
                {
                    BasePath = arxivarApiBasePath
                };

                var authApi = new AuthenticationApi(configuration);

                var authenticationTokenRequestDTO = new AuthenticationTokenRequestDTO();
                authenticationTokenRequestDTO.Username = arxivarUsername;
                authenticationTokenRequestDTO.Password = arxivarPassword;
                authenticationTokenRequestDTO.ClientId = "ArxivarNextDev";
                authenticationTokenRequestDTO.ClientSecret = arxivarClientSecret;

                //Creo il token di autenticazione di Arxivar
                var arxToken = authApi.AuthenticationGetToken(authenticationTokenRequestDTO);

                configuration.ApiClient.RestClient.AddDefaultHeader("Authorization", "Bearer " + arxToken.AccessToken);
                //Creo l'istanza dell'API per la gestione dei profili
                var profileApi = new ProfilesApi(configuration);

                // Elimino il documento identificato dal numero di documento
                profileApi.ProfilesDeleteProfile(systemId);
                return true;
            }
            catch (Exception e)
            {
                throw;
            }
        }

        //-------------------------------------------------------------------------------------------------------------
        //                                              Funzioni ausiliarie
        //-------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Converte uno stream in un array di byte.
        /// </summary>
        /// <param name="input">stream da convertire</param>
        /// <returns></returns>
        private static byte[] StreamToByteArray(Stream input)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                input.CopyTo(ms);
                return ms.ToArray();
            }
        }



        /// <summary>
        /// Restituisce i dati dei documenti ARXivar in base ai criteri di ricerca forniti.
        /// </summary>
        /// <param name="content"></param>
        /// <returns></returns>
        public static async Task<List<List<string>>> GetArxData(Dictionary<string, JsonElement> content)
        {
            List<SearchDTO> listOfSearchDTO;
            SelectDTO selectDTO = null;
            int docNumber = -1;
            List <List<string>> documents = new();


            Configuration configuration = new Configuration()
            {
                BasePath = arxivarApiBasePath
            };

            var authApi = new AuthenticationApi(configuration);

            var authenticationTokenRequestDTO = new AuthenticationTokenRequestDTO();
            authenticationTokenRequestDTO.Username = arxivarUsername;
            authenticationTokenRequestDTO.Password = arxivarPassword;
            authenticationTokenRequestDTO.ClientId = "ArxivarNextDev";
            authenticationTokenRequestDTO.ClientSecret = arxivarClientSecret;

            var arxToken = authApi.AuthenticationGetToken(authenticationTokenRequestDTO);

            configuration.ApiClient.RestClient.AddDefaultHeader("Authorization", "Bearer " + arxToken.AccessToken);

            var documentsApi = new Abletech.WebApi.Client.Arxivar.Api.DocumentsApi(configuration);

            //Estrapolo le informazioni per fare la ricerca
            var origin_searchesApi = BuildDocumentDTOs(configuration, out selectDTO, out listOfSearchDTO, content);

            var searchCriteriaMultipleDto = new SearchCriteriaMultipleDto();
            searchCriteriaMultipleDto.SearchFilterDtoList = listOfSearchDTO;
            searchCriteriaMultipleDto.SelectFilterDto = selectDTO;


            var info = searchCriteriaMultipleDto.ToJson();

            //Cerca il documento in base ai campi di ricerca forniti (solo 1 documento o più di 1?)
            var origin_listRowSearchResult = await origin_searchesApi.SearchesV3PostSearchMultipleAsync(searchCriteriaMultipleDto);


            //Estraggo il risultato
            JObject origin_JObject = (JObject)origin_listRowSearchResult;

            var origin_JObjectData = origin_JObject.GetValue("data");

            foreach (var jItem in origin_JObjectData)
            {
                var jArray = ((JArray)jItem);
                int i = -1, j;
                List<string> contenuto = new();
                foreach (var jElement in jArray)
                {
                    i++;
                    var jElementValue = jElement.ToString();
                    if (!String.IsNullOrEmpty(jElementValue))
                    {
                        contenuto.Add(jElementValue);
                    }
                }
                documents.Add(contenuto);
            }
            return documents;
        }
    }

    public class SearchV3DTOBuilder
    {
        private int _searchListIndex = 0;

        private List<SearchDTO> _searchDTO = null;

        private FieldBaseForSearchStringDto _search = null;
        private FieldBaseForSearchListDto _searchLst = null;
        private FieldBaseForSearchBoolDto _searchBln = null;

        // NB: DateTime and Integer field searches are Not implemented yet 
        //private FieldBaseForSearchDateTimeDto _searchDt = null;

        private FieldBaseForSearchIntDto _searchInt = null;

        public SearchV3DTOBuilder(List<SearchDTO> searchDTO)
        {
            _searchListIndex = (_searchDTO = searchDTO).Count - 1;
        }

        public SearchV3DTOBuilder(SearchesV3Api searchesApi)
        {
            _searchDTO = searchesApi.SearchesV3Get();
        }

        public SearchDTO SearchDTO
        {
            get
            {
                return _searchDTO[_searchListIndex];
            }
        }

        public SearchV3DTOBuilder AddFieldBaseForSearchInt(FieldBaseForSearchIntDto item)
        {
            _searchDTO[_searchListIndex].Fields.Add(item);

            return this;
        }

        public SearchV3DTOBuilder AddFieldBaseForSearchInt(FieldBaseForSearchDTO item, int valore1, int? valore2 = null, int @operator = 3)
        {
            _searchInt = (FieldBaseForSearchIntDto)item;
            _searchInt.Operator = @operator;
            _searchInt.Valore1 = valore1;

            _searchInt.DefaultOperator = @operator;

            if (valore2.HasValue)
            {
                _searchInt.Valore2 = valore2;
            }

            _searchDTO[_searchListIndex].Fields.Add(_searchInt);

            return this;
        }

        public SearchV3DTOBuilder AddFieldBaseForSearchString(FieldBaseForSearchDTO item, string valore1, string valore2 = null, int @operator = 1)
        {
            _search = (FieldBaseForSearchStringDto)item;
            _search.Operator = @operator;
            _search.Valore1 = valore1;

            if (!String.IsNullOrEmpty(valore2))
            {
                _search.Valore2 = valore2;
            }

            _searchDTO[_searchListIndex].Fields.Add(_search);

            return this;
        }

        public SearchV3DTOBuilder AddFieldBaseForSearchList(FieldBaseForSearchDTO item, string valore1, string valore2 = null, int @operator = 1)
        {
            _searchLst = (FieldBaseForSearchListDto)item;
            _searchLst.Operator = @operator;

            if (_searchLst.Valore1 == null)
            {
                _searchLst.Valore1 = new List<string>();
            }

            _searchLst.Valore1.Add(valore1);

            if (!String.IsNullOrEmpty(valore2))
            {
                if (_searchLst.Valore2 == null)
                {
                    _searchLst.Valore2 = new List<string>();
                }
                _searchLst.Valore2.Add(valore2);
            }

            _searchDTO[_searchListIndex].Fields.Add(_searchLst);

            return this;
        }

        public SearchV3DTOBuilder AddFieldBaseForSearchBool(FieldBaseForSearchDTO item, bool? valore1, bool? valore2 = null, int @operator = 3)
        {
            _searchBln = (FieldBaseForSearchBoolDto)item;
            _searchBln.Operator = @operator;
            _searchBln.Valore1 = valore1;

            if (valore2.HasValue)
            {
                _searchBln.Valore2 = valore2;
            }
            else
            {
                _searchBln.Valore2 = null;
            }

            _searchDTO[_searchListIndex].Fields.Add(_searchBln);

            return this;
        }

        public List<SearchDTO> Build()
        {
            return _searchDTO;
        }
    }

    public class ArxSearchElement
    {
        /// <summary>
        /// Nome del campo da cercare.
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Tipo del campo, i valori accettati sono
        /// <list type="bullet">
        ///    <item>int</item>
        ///    <item>string</item>
        ///    <item>bool</item>
        ///    <item>list</item>
        /// </list>
        /// </summary>
        public string Type { get; set; }

        /// <summary>
        /// Valore del campo da cercare.
        /// </summary>
        public string Value { get; set; }

        /// <summary>
        /// Operatore di confronto per il filtro del campo.
        /// <list type="bullet">
        ///     <item>0 = non impostato </item>
        ///     <item>1 = minore </item>
        ///     <item>2 = minore o uguale </item>
        ///     <item>3 = uguale </item>
        ///     <item>4 = maggiore o uguale </item>
        ///     <item>5 = maggiore </item>
        ///     <item>6 = diverso </item>
        ///     <item>7 = compreso </item>
        ///     <item>8 = nullo </item>
        ///     <item>9 = non nullo </item>
        ///     <item>10 = nullo o zero </item>
        ///     <item>11 = Non nullo e non zero </item>
        ///     <item>12 = escluso </item>
        /// </list>
        /// </summary>
        public int Operator { get; set; }
        public bool IsBase { get; set; }

        public ArxSearchElement(string name, string type, string value, int @operator, bool isBase)
        {
            Name = name;
            Type = type;
            Value = value;
            Operator = @operator;
            IsBase = isBase;
        }

        public ArxSearchElement()
        {
            Name = "";
            Type = "";
            Value = "";
            Operator = 0;
            IsBase = false;
        }
    }

    public class ArxSelectElement
    {
        /// <summary>
        /// Nome del campo selezionato
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// Indica se il campo è selezionato o meno
        /// </summary>
        public bool Selected { get; set; }

        /// <summary>   
        /// Ordinamento del campo, può avere due valori: asc e desc
        /// </summary>
        public string OrderBy { get; set; }

        /// <summary>
        /// Indice del campo nella lista dei campi selezionati
        /// </summary>
        public int Index { get; set; }


        public ArxSelectElement(string name, bool selected, string orderBy, int index)
        {
            Name = name;
            Selected = selected;
            OrderBy = orderBy;
            Index = index;
        }
        public ArxSelectElement()
        {
            Name = "";
            Selected = false;
            OrderBy = "";
            Index = 0;
        }
    }
}


