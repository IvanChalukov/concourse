package pipelineserver

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"code.cloudfoundry.org/lager/v3"
	"github.com/concourse/concourse/atc"
	"github.com/concourse/concourse/atc/api/accessor"
	"github.com/concourse/concourse/atc/db"
)

func (s *Server) ChownPipeline(team db.Team) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logger := s.logger.Session("chown-pipeline")

		data, err := io.ReadAll(r.Body)
		if err != nil {
			logger.Error("failed-to-read-body", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		var chown atc.ChownRequest
		err = json.Unmarshal(data, &chown)
		if err != nil {
			logger.Error("failed-to-unmarshal-body", err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		newTeam, found, err := s.teamFactory.FindTeam(chown.NewTeam)
		if err != nil {
			logger.Error("failed-to-get-team", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		if !found {
			logger.Error("team-not-found", fmt.Errorf("team %s not found", chown.NewTeam))
			w.WriteHeader(http.StatusNotFound)
			return
		}

		acc := accessor.GetAccessor(r)

		if !acc.IsAuthorized(chown.NewTeam) {
			logger.Error("not authorized", err)
			w.WriteHeader(http.StatusForbidden)
			return
		}

		fmt.Println("=> chown", chown.NewTeam)
		fmt.Println("=> team", newTeam.ID())

		pipelineName := r.FormValue(":pipeline_name")
		changed, err := team.ChownPipeline(pipelineName, newTeam.ID())
		if err != nil {
			logger.Error("failed-to-update-name", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		if !changed {
			logger.Info("pipeline-not-found", lager.Data{"pipeline_name": pipelineName})
			w.WriteHeader(http.StatusNotFound)
			return
		}

		err = json.NewEncoder(w).Encode(atc.SaveConfigResponse{
			Errors:   []string{},
			Warnings: []atc.ConfigWarning{},
		})
		if err != nil {
			logger.Error("failed-to-encode-response", err)
			w.WriteHeader(http.StatusInternalServerError)
		}
		// if err := team.RenamePipeline(pipelineName); err != nil {
		// 	w.WriteHeader(http.StatusInternalServerError)
		// 	return
		// }

		w.WriteHeader(http.StatusOK)
	})
}
