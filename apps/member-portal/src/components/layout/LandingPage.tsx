// Copyright (c) 2024-2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import {
  Container,
  Typography,
  Button,
  Box,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Chip,
  TextField,
  LinearProgress,
} from "@mui/material";
import { useEffect, useState } from "react";
import Header from "../common/Header";
import { Navigate, useLocation } from "react-router-dom";
import CloseIcon from "@mui/icons-material/Close";
import apiClient from "../../services/apiClient";
import { useAuth } from "../common/AuthProvider";
import Cookies from "js-cookie";
import axios from "axios";
import {
  BULK_EXPORT_KICKOFF_URL,
  ORGANIZATION_SERVICE_URL,
} from "../../configs/Constants";
import { useDispatch, useSelector } from "react-redux";
import {
  updateRequestUrl,
  updateRequest,
  updateRequestMethod,
  resetCdsRequest,
} from "../redux/cdsRequestSlice";
import { updateCdsResponse, resetCdsResponse } from "../redux/cdsResponseSlice";
import Profile from "../common/Profile";
import { updateLoggedUser } from "../redux/loggedUserSlice";

interface Payer {
  id: number;
  name: string;
}

export const LandingPage = () => {
  const { isAuthenticated } = useAuth();
  const [isLoginLoaded, setIsLoginLoaded] = useState(false);
  const [name, setName] = useState("");
  const [exportLabel, setExportLabel] = useState("Export");
  const [status, setStatus] = useState("Member Not Resolved.");
  const [avatarUrl, setAvatarUrl] = useState(
    "https://i.pravatar.cc/100?img=58"
  );
  const location = useLocation();
  const memberId = location.state?.memberId || "nil";
  const [error, setError] = useState("");
  const [payerList, setPayerList] = useState<Payer[]>([]);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [oldMemberId, setOldMemberId] = useState("");
  const [exportId, setExportId] = useState("");
  const [exportStatus, setExportStatus] = useState("0");
  const dispatch = useDispatch();
  const [isExportCompleted, setIsExportCompleted] = useState(false);

  // State to manage selected options
  const [selectedOptions, setSelectedOptions] = useState([]);
  const Config = window.Config;

  useEffect(() => {
    const fetchUserInfo = async () => {
      const loggedUser = await fetch("/auth/userinfo")
        .then((response) => response.json())
        .then((data) => {
          console.log("Logged User Info: ", data);
          setIsLoginLoaded(true);
          return data;
        });

      if (loggedUser) {
        setName(loggedUser.first_name);
        dispatch(
          updateLoggedUser({
            username: loggedUser.username,
            first_name: loggedUser.first_name,
            last_name: loggedUser.last_name,
            id: loggedUser.id,
          })
        );
      }
    };

    fetchUserInfo();
  }, [dispatch]);

  useEffect(() => {
    const fetchOrganizations = async (): Promise<Payer[]> => {
      try {
        const response = await fetch(ORGANIZATION_SERVICE_URL);
        const data = await response.json();
        return data.entry.map((entry: any) => ({
          id: entry.resource.id,
          name: entry.resource.name,
        }));
      } catch (error) {
        console.error("Error fetching organizations:", error);
        return [];
      }
    };

    const loadOrganizations = async () => {
      const payers = await fetchOrganizations();
      console.log(payers);
      setPayerList(payers);
    };

    loadOrganizations();
  }, []);

  // Handle selection of options
  const handleSelectChange = (event: { target: { value: any } }) => {
    const { value } = event.target;
    handlePayerSelection(value);
    setSelectedOptions(value); // Update selected options
  };

  // Handle removal of a tag (chip)
  const handleRemoveTag = (optionToRemove: any) => {
    setSelectedOptions(
      selectedOptions.filter((option) => option !== optionToRemove)
    );
  };

  const handleSubmit = (e: { preventDefault: () => void }) => {
    dispatch(resetCdsRequest());
    dispatch(resetCdsResponse());

    e.preventDefault();
    setExportLabel("Exporting...");
    setStatus("Exporting...");

    setExporting(true);
    console.log("Submitted name:", selectedOptions);

    const postOrganizationId = async () => {
      const memberID = oldMemberId;
      const payload = [{ id: memberID }];
      dispatch(updateRequestMethod("POST"));
      dispatch(updateRequestUrl("/bulk-export-client/v1.0/export"));
      dispatch(updateRequest({ id: memberID }));

      try {
        const response = await axios.post(BULK_EXPORT_KICKOFF_URL, payload, {
          headers: {
            "Content-Type": "application/json",
          },
        });
        console.log("POST response:", response.data);
        dispatch(
          updateCdsResponse({
            cards: response.data,
            systemActions: {},
          })
        );

        const diagnostics: string = response.data.issue?.[0]?.diagnostics || "";
        const match = diagnostics.match(/ExportId:\s([\w-]+)/);
        if (match && match[1]) {
          setExportId(match[1]);
          console.log("Export ID:", match[1]);
          localStorage.setItem("exportId", match[1]);
          checkStatusUntilDownloaded(match[1]);
        } else {
          console.warn("Export ID not found in diagnostics message.");
        }
      } catch (error) {
        console.error("Error posting data:", error);
      }
    };

    const checkStatusUntilDownloaded = async (exportId: string) => {
      const interval = setInterval(async () => {
        try {
          const response = await axios.get(Config.bulkExportStatusUrl, {
            params: { exportId: exportId },
          });
          const currentStatus = response.data.lastStatus;
          console.log("Checking status:", currentStatus);

          setStatus(currentStatus);

          if (currentStatus === "Downloaded") {
            clearInterval(interval);
            setStatus("Export Completed.");
            setIsExportCompleted(true);
            setExportStatus("100");
          }
        } catch (error) {
          console.error("Error checking status:", error);
        }
      }, 300); // Check every 0.3 seconds
    };

    postOrganizationId();
  };

  const handlePayerSelection = (value: string) => {
    console.log("Selected Payer", value);
    // const matchUrl = "/member/" + memberId + "/matchPatient";
    const matchUrl = "/3e2fa8c7-28d2-47e8-b739-1cf48a457983";
    try {
      axios
        .get("https://run.mocky.io/v3" + matchUrl)
        .then((response) => {
          // console.log(response);
          if (response.status === 200) {
            console.log("Member match trigger successful: ");
            console.log(response);
            console.log("----------");
            // console.log("MemberID: ", response.data.resourceType);
            // setOldMemberId(response.data.oldMemberId);
            setOldMemberId("644d85af-aaf9-4068-ad23-1e55aedd5205");
            setError("");
            setStatus("Ready");
          } else {
            setError("Match failed. Please retry");
          }
        })
        .catch((error) => {
          console.error("Error:", error);
          setError("Match failed. Please retry");
          setStatus("Member Not Resoved.");
        })
        .finally(() => {
          setLoading(false); // Turn off loading after API call completes
        });
    } catch (error) {
      console.error("Error:", error);
      setError("Error fetching data");
    }
  };

  const loggedUser = useSelector((state: any) => state.loggedUser);

  return isAuthenticated ? (
    <Container>
      <Header
        userName={loggedUser.first_name}
        avatarUrl={avatarUrl}
        isLoggedIn={true}
      />
      {isLoginLoaded ? (
        <div>
          <Profile
            userName={loggedUser.username}
            firstName={loggedUser.first_name}
            lastName={loggedUser.last_name}
            id={loggedUser.id}
          />

          <Box sx={{ mt: 4, mb: 4, ml: 2, mr: 2 }}>
            <Box>
              <Typography variant="h4">Fetch previous payer data</Typography>
              <Typography variant="h6" sx={{ mt: 2, mb: 4 }}>
                Welcome to the USPayer Data Exchange Portal. If you haven't yet
                synced your data with your previous, please select your previous
                payer(s) and click 'Export' to securely transfer your data to
                USPayer. The transfer will run in the background, and you will
                be notified once the process is complete.
              </Typography>
            </Box>

            <Box
              component="form"
              onSubmit={handleSubmit}
              sx={{
                p: 2,
                border: "1px dashed grey",
                padding: 4,
                borderRadius: 2,
              }}
            >
              <FormControl fullWidth variant="outlined" sx={{ mb: 2 }}>
                <InputLabel id="select-payer-label">
                Select previous payer
                </InputLabel>
                <Select
                  labelId="select-payer-label"
                  id="select-payer"
                  multiple
                  value={selectedOptions}
                  onChange={handleSelectChange}
                  label="Select previous payer"
                >
                  {payerList.map((payer, index) => (
                    <MenuItem key={index} value={payer.id}>
                      {payer.name}
                    </MenuItem>
                  ))}
                </Select>
                {/* Display selected options as tags (chips) */}
                <div
                  style={{
                    marginTop: "20px",
                    display: "grid",
                    gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))",
                    gap: "20px",
                  }}
                >
                  {selectedOptions.map((option) => (
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}
                    >
                      <Box sx={{ width: "100%" }}>
                        <Chip
                          key={option}
                          label={
                            payerList.find((payer) => payer.id === option)?.name
                          }
                          onDelete={() => handleRemoveTag(option)} // Close icon removes the tag
                          deleteIcon={<CloseIcon />}
                        />
                        <TextField
                          label="Member ID"
                          type="text"
                          fullWidth
                          variant="outlined"
                          margin="normal"
                          value={oldMemberId}
                          onChange={(event: { target: { value: any } }) =>
                            setOldMemberId(event.target.value)
                          }
                        />
                      </Box>
                    </div>
                  ))}
                </div>
                <Box
                  sx={{
                    mt: 2,
                    mb: 4,
                    border: "1px solid lightGrey",
                    padding: 2,
                    borderRadius: 1,
                  }}
                >
                  <Typography variant="h5">Status: {status}</Typography>
                  <Box sx={{ display: "flex", alignItems: "center" }}>
                    <Box sx={{ width: "100%", mt: 2, height: 6 }}>
                      <LinearProgress
                        variant="determinate"
                        value={+exportStatus}
                      />
                    </Box>
                    <Box sx={{ minWidth: 40, paddingLeft: 2, height: 10 }}>
                      <Typography
                        variant="body2"
                        sx={{ color: "text.secondary" }}
                      >{`${Math.round(+exportStatus)}%`}</Typography>
                    </Box>
                  </Box>
                  {isExportCompleted && (
                    <Typography variant="body1" sx={{ mt: 2, color: "black" }}>
                      Export ID: {exportId}
                    </Typography>
                  )}
                </Box>
                {isExportCompleted || error != "" ? (
                  <>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={() => window.open("/exported-data", "_blank")}
                      sx={{ mt: 2 }}
                    >
                      View Exported Data
                    </Button>
                  </>
                ) : (
                  <>
                    <Button
                      variant="contained"
                      color="primary"
                      onClick={handleSubmit}
                      disabled={exporting || error != "" || oldMemberId === ""}
                    >
                      {exportLabel}
                    </Button>
                  </>
                )}
              </FormControl>
            </Box>
          </Box>
        </div>
      ) : (
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            height: "50vh",
          }}
        >
          <Typography variant="h6">Loading...</Typography>
        </div>
      )}
    </Container>
  ) : (
    <Navigate to="/login" replace />
  );
};
