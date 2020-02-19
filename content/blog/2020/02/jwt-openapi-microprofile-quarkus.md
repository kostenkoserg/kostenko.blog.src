title=Well secured and documented REST API with Eclipse Microprofile and Quarkus
date=2020-02-15
type=post
tags=microprofile, jwt, quarkus, openapi, swagger
status=published
~~~~~~
Eclipse Microprofile specification provides several many helpful sections about building well designed microservice-oriented applications. **OpenAPI**, **JWT Propagation** and **JAX-RS** - the ones of them.
![microprofile, jwt, openapi, jax-rs](/img/2020-02-jwt-openapi-jaxrs-microprofile.png)
To see how it works on practice let's design two typical REST resources: insecured **token** to generate JWT and secured  **user**, based on Quarkus Microprofile implementation.

Easiest way to bootstrap Quarkus application from scratch is generation project structure by provided starter page - **[code.quarkus.io](https://code.quarkus.io/)**. Just select build tool you like and extensions you need. In our case it is:

 * **SmallRye JWT**
 * **SmallRye OpenAPI**

I prefer **gradle**, - and my `build.gradle` looks pretty simple
```java
group 'org.kostenko'
version '1.0.0'
plugins {
    id 'java'
    id 'io.quarkus'
}
repositories {
     mavenLocal()
     mavenCentral()
}
dependencies {
    implementation 'io.quarkus:quarkus-smallrye-jwt'
    implementation 'io.quarkus:quarkus-smallrye-openapi'
    implementation 'io.quarkus:quarkus-resteasy-jackson'    
    implementation 'io.quarkus:quarkus-resteasy'
    implementation enforcedPlatform("${quarkusPlatformGroupId}:${quarkusPlatformArtifactId}:${quarkusPlatformVersion}")
    testImplementation 'io.quarkus:quarkus-junit5'
    testImplementation 'io.rest-assured:rest-assured'
}
compileJava {
    options.compilerArgs << '-parameters'
}
```
Now we are ready to improve standard JAX-RS service with OpenAPI and JWT stuff.
```java
...
import javax.annotation.security.*;
import org.eclipse.microprofile.jwt.Claim;
import org.eclipse.microprofile.openapi.annotations.*;

@RequestScoped
@Path("/user")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
@Tags(value = @Tag(name = "user", description = "All the user methods"))
@SecurityScheme(securitySchemeName = "jwt", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "jwt")
public class UserResource {

    @Inject
    @Claim("userId")
    Optional<JsonNumber> userId;

    @POST
    @PermitAll
    @Path("/token/{userName}")
    @APIResponses(value = {
        @APIResponse(responseCode = "400", description = "JWT generation error"),
        @APIResponse(responseCode = "200", description = "JWT successfuly created.", content = @Content(schema = @Schema(implementation = User.class)))})
    @Operation(summary = "Create JWT token by provided user name")
    public User getToken(@PathParam("userName") String userName) {
        return null;
    }

    @GET
    @RolesAllowed("user")
    @Path("/current")
    @SecurityRequirement(name = "jwt", scopes = {})
    @APIResponses(value = {
        @APIResponse(responseCode = "401", description = "Unauthorized Error"),
        @APIResponse(responseCode = "200", description = "Return user data", content = @Content(schema = @Schema(implementation = User.class)))})
    @Operation(summary = "Return user data by provided JWT token")
    public User getUser() {
        return new User();
    }
}
```
First let's take a brief review of used **[Open API](https://github.com/eclipse/microprofile-open-api)** annotations:

 * `@Tags(value = @Tag(name = "user", description = "All the user methods"))` -  Represents a tag. Tag is a meta-information you can use to help organize your API end-points.
 * `@SecurityScheme(securitySchemeName = "jwt", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "jwt")` - Defines a security scheme that can be used by the operations.
 * `@APIResponse(responseCode = "401", description = "Unauthorized Error")` - Corresponds to the OpenAPI response model object which  describes a single response from an API Operation.
 * `@Operation(summary = "Return user data by provided JWT token")` - Describes an operation or typically a HTTP method against a specific path.
 * `@Schema(implementation = User.class)` - Allows the definition of input and output data types.

To more details about Open API annotations, please refer to the **[MicroProfile OpenAPI Specification](https://github.com/eclipse/microprofile-open-api/blob/master/spec/src/main/asciidoc/microprofile-openapi-spec.adoc)**.

After start the application, you will able to get your Open API description in the  **.yaml** format by the next URL http://0.0.0.0:8080/openapi or even enjoy **Swagger UI** as well by http://0.0.0.0:8080/swagger-ui/ :
![microprofile, openapi, swagger-ui](/img/2020-02-swagger-ui.png)

**Note** By default swagger-ui available in the dev mode only. If you would like to keep swagger on production, - add next property to your `application.properties`
```java
quarkus.swagger-ui.always-include=true
```
Second part of this post is a **[JWT role based access control(RBAC)](https://github.com/eclipse/microprofile-jwt-auth)** for microservice endpoints. JSON Web Tokens are an open, industry standard  [RFC 7519](https://tools.ietf.org/html/rfc7519) method for representing claims securely between two parties and below we will see how easy it can be integrated in your application with Eclipse Microprofile.

As JWT suggests usage of cryptography - we need to generate public\private key pair before start coding:
```bash
# Generate a private key
openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048

# Derive the public key from the private key
openssl rsa -pubout -in private_key.pem -out public_key.pem
```
