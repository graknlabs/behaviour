package grakn.verification.resolution.test;

import grakn.client.GraknClient;
import grakn.verification.resolution.kbtest.ResolutionBuilder;
import graql.lang.Graql;
import graql.lang.query.GraqlGet;
import graql.lang.statement.Statement;
import org.junit.Test;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.Set;

import static grakn.verification.resolution.common.Utils.getStatements;
import static org.junit.Assert.assertEquals;

public class ResolutionBuilderIT {

    private static Path SCHEMA_PATH_1 = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case1/schema.gql");
    private static Path DATA_PATH_1 = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case1/data.gql");
    private static Path SCHEMA_PATH_2 = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case2/schema.gql");
    private static Path DATA_PATH_2 = Paths.get("/Users/jamesfletcher/programming/verification/resolution/cases/case2/data.gql");

//      Case 1
//    String inferenceQuery = "match $ar isa area, has name $ar-name; $cont isa continent, has name $cont-name; $lh(location-hierarchy_superior: $cont, location-hierarchy_subordinate: $ar) isa location-hierarchy; get;";

    @Test
    public void testQueryIsCorrect() {
        String graknHostUri = "localhost:48555";
        String graknKeyspace = "case2";

        GraqlGet inferenceQuery = Graql.parse("match $transaction isa transaction, has currency $currency; get;");

        GraknClient grakn = new GraknClient(graknHostUri);

        try (GraknClient.Session session = grakn.session(graknKeyspace)) {
//            try {
//                // Load a schema incl. rules
//                loadGqlFile(session, SCHEMA_PATH_2);
//                // Load data
//                loadGqlFile(session, DATA_PATH_2);
//            } catch (IOException e) {
//                e.printStackTrace();
//                System.exit(1);
//            }

            Set<Statement> expectedStatements = getStatements(Graql.parsePatternList(
//                    From the initial answer:
                    "$transaction has currency $currency;\n" +
                    "$transaction id V86232;\n" +
                    "$currency id V36912;\n" +
                    "$transaction isa transaction;\n" +

//                    From the explained answers:
                    "$country has currency $currency;\n" +
                    "$country isa country;\n" +
                    "$country id V40968;\n" +
                    "$currency id V36912;\n" +

                    "$lh (location-hierarchy_superior: $country, location-hierarchy_subordinate: $city) isa location-hierarchy;\n" +
                    "$country isa country;\n" +
                    "$city id V20688;\n" +
                    "$country id V40968;\n" +
                    "$city isa city;\n" +
                    "$lh id V41080;\n" +

                    "$city id V20688;\n" +
                    "$transaction id V86232;\n" +
                    "$l1 (locates_located: $transaction, locates_location: $city) isa locates;\n" +
                    "$l1 id V90328;\n" +
                    "$city isa city;\n" +
                    "$transaction isa transaction;\n" +

                    "$country isa country;\n" +
                    "$locates id V4224;\n" +
                    "$locates (locates_located: $transaction, locates_location: $country) isa locates;\n" +
                    "$transaction id V86232;\n" +
                    "$country id V40968;\n" +
                    "$transaction isa transaction;"
            ));

            ResolutionBuilder qb = new ResolutionBuilder();
            try (GraknClient.Transaction tx = session.transaction().read()) {
                List<GraqlGet> kbCompleteQueries = qb.build(tx, inferenceQuery);
                GraqlGet kbCompleteQuery = kbCompleteQueries.get(0);
                Set<Statement> statements = kbCompleteQuery.match().getPatterns().statements();
                assertEquals(expectedStatements, statements);
            }
        }
    }
}
