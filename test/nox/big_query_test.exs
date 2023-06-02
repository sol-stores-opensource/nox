defmodule Nox.BigQueryTest do
  use Nox.DataCase, async: true

  alias Nox.BigQuery

  @stable_dt ~U[2022-04-18 17:45:53.139881Z]

  test "schema evolution" do
    data = %{foo: "bar"}
    schema_a = BigQuery.data_to_schema(data)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_STRING",
                 type: "STRING"
               }
             ]
           } == schema_a

    data = %{bar: "zar"}
    schema_b = BigQuery.data_to_schema(data)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_STRING",
                 type: "STRING"
               }
             ]
           } == schema_b

    schema_c = BigQuery.merge_schema(schema_a, schema_b)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_STRING",
                 type: "STRING"
               }
             ]
           } == schema_c

    data = %{
      nested1: %{
        a_int: 1,
        a_dec: Decimal.new("4.454"),
        a_bool_t: true,
        a_bool_f: false,
        a_float: 1.1,
        a_now: Timex.now(),
        a_time: Time.utc_now(),
        a_date: Date.utc_today()
      }
    }

    schema_d = BigQuery.data_to_schema(data)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: [
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_f_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_t_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_date_DATE",
                     type: "DATE"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_dec_NUMERIC",
                     type: "NUMERIC"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_float_FLOAT",
                     type: "FLOAT"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_int_INTEGER",
                     type: "INTEGER"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_now_TIMESTAMP",
                     type: "TIMESTAMP"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_time_TIME",
                     type: "TIME"
                   }
                 ],
                 mode: "NULLABLE",
                 name: "nested1_RECORD",
                 type: "RECORD"
               }
             ]
           } == schema_d

    schema_e = BigQuery.merge_schema(schema_c, schema_d)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: [
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_f_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_t_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_date_DATE",
                     type: "DATE"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_dec_NUMERIC",
                     type: "NUMERIC"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_float_FLOAT",
                     type: "FLOAT"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_int_INTEGER",
                     type: "INTEGER"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_now_TIMESTAMP",
                     type: "TIMESTAMP"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_time_TIME",
                     type: "TIME"
                   }
                 ],
                 maxLength: nil,
                 mode: "NULLABLE",
                 name: "nested1_RECORD",
                 type: "RECORD"
               }
             ]
           } == schema_e

    data = %{
      foo: Timex.now(),
      nested1: %{
        a_int: %{
          b_int: 2
        }
      }
    }

    schema_f = BigQuery.data_to_schema(data)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_TIMESTAMP",
                 type: "TIMESTAMP"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: [
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: [
                       %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                         fields: nil,
                         mode: "NULLABLE",
                         name: "b_int_INTEGER",
                         type: "INTEGER"
                       }
                     ],
                     mode: "NULLABLE",
                     name: "a_int_RECORD",
                     type: "RECORD"
                   }
                 ],
                 mode: "NULLABLE",
                 name: "nested1_RECORD",
                 type: "RECORD"
               }
             ]
           } == schema_f

    schema_g = BigQuery.merge_schema(schema_e, schema_f)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: [
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_f_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_bool_t_BOOLEAN",
                     type: "BOOLEAN"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_date_DATE",
                     type: "DATE"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_dec_NUMERIC",
                     type: "NUMERIC"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_float_FLOAT",
                     type: "FLOAT"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_int_INTEGER",
                     type: "INTEGER"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_now_TIMESTAMP",
                     type: "TIMESTAMP"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "a_time_TIME",
                     type: "TIME"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: [
                       %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                         fields: nil,
                         mode: "NULLABLE",
                         name: "b_int_INTEGER",
                         type: "INTEGER"
                       }
                     ],
                     mode: "NULLABLE",
                     name: "a_int_RECORD",
                     type: "RECORD"
                   }
                 ],
                 mode: "NULLABLE",
                 name: "nested1_RECORD",
                 type: "RECORD"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_TIMESTAMP",
                 type: "TIMESTAMP"
               }
             ]
           } == schema_g

    schema_h = BigQuery.merge_schema(schema_g, schema_g)

    assert schema_h == schema_g
  end

  test "schema merging" do
    base = BigQuery.data_to_schema(%{foo: "bar"})

    rows = [
      %{foo: "bar"},
      %{foo: "bar", bar: "zar"},
      %{foo: "bar", bar: %{other: 1}, zar: Timex.now()},
      %{foo: "bar", bar: %{other: "str"}},
      %{bar: false},
      %{bar: nil, empty_should_be_stripped_out: %{}}
    ]

    needed_schema = BigQuery.data_to_schema(rows)

    final_schema = BigQuery.merge_schema(base, needed_schema)

    assert %GoogleApi.BigQuery.V2.Model.TableSchema{
             fields: [
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "foo_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_STRING",
                 type: "STRING"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: [
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "other_INTEGER",
                     type: "INTEGER"
                   },
                   %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                     fields: nil,
                     mode: "NULLABLE",
                     name: "other_STRING",
                     type: "STRING"
                   }
                 ],
                 mode: "NULLABLE",
                 name: "bar_RECORD",
                 type: "RECORD"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "zar_TIMESTAMP",
                 type: "TIMESTAMP"
               },
               %GoogleApi.BigQuery.V2.Model.TableFieldSchema{
                 fields: nil,
                 mode: "NULLABLE",
                 name: "bar_BOOLEAN",
                 type: "BOOLEAN"
               }
             ]
           } == final_schema
  end

  test "row to bq_json" do
    row = %{foo: "bar", bar: %{other: 1, oops: nil}, zar: @stable_dt}

    bq_json = BigQuery.data_to_bq_struct(row)

    assert %GoogleApi.BigQuery.V2.Model.TableDataInsertAllRequestRows{
             insertId: nil,
             json: %{
               "bar_RECORD" => %{"other_INTEGER" => 1},
               "foo_STRING" => "bar",
               "zar_TIMESTAMP" => "2022-04-18T17:45:53.139881Z"
             }
           } == bq_json
  end
end
